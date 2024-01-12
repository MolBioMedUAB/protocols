import numpy as np
import matplotlib.pyplot as plt

import argparse

plt.style.use('ggplot')


def parser():

    parser = argparse.ArgumentParser(description='Script for obtaining PMF profiles for multi-frame steered MDs simulatewd with AMBER.')

    """
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--option1", help="Description for option 1")
    group.add_argument("--option2", help="Description for option 2")
    """

    parser.add_argument('-i', '--input',
                        help='Input .dat files from Amber SMD simulations. If more than one .dat is input, the PMF will be calculated. Otherwise, if only one .dat file is input, the work will be output.',
                        required=True,
                        nargs='+')

    parser.add_argument('-t', '--temperature',
                        help='Working temperature for calculating the PMF. 310.15 K (37ºC) is the default value.',
                        required=False,
                        default=310.15,
                        type=float,
                        )

    parser.add_argument('-o', '--output',
                        help='Output files name. Default is \'pmf\'.',
                        default='pmf')

    parser.add_argument('-s', '--show',
                        help='Trigger for previsualise the generated plots',
                        default=False,
                        action='store_true')

    return parser.parse_args()

def read_input_files(input):

    smds = []
    for file in input:

        f = open(file).readlines() # lines 1-3 are the headers and -3-last is the total work done
        data = []
        for l in range(len(f)):
            if not f[l].startswith('#'):
                data.append(f[l].split())

        smds.append(data)

    #smds_np = np.array(smds)

    return smds


def calculate_2n_order_cumulant(smds, temp=310.15, output='pmf'):

    beta =1/(0.001987 * temp)

    if len(smds) == 1:
        print('No cumulant can be calculated since only one calculation has been provided.')
        print('The plot will be generated with work instead of PMF')
        output_type = 'w'

    else :
        output_type='pmf'

    smd_analysed = []
    works        = []

    f_out = open(output + '_processed.csv', 'w')

    for l in range(len(smds[0])):

        tot_W = 0
        tot_W_sq = 0
        tot_F = 0
        works.append([])
        for smd in smds:
            tot_W    += float(smd[l][4])
            tot_W_sq += float(smd[l][4])**2
            tot_F    += float(smd[l][3])*(float(smd[l][1])-float(smd[l][2]))
            works[-1].append(smd[l][4])


        avg_W = (1/len(smds))*tot_W
        avg_W_sq = (1/len(smds))*tot_W_sq
        avg_F = (1/len(smds))*tot_F

        cum = avg_W - 1/2*beta*(avg_W_sq-(avg_W**2))



        smd_analysed.append(
            [round(float(smd[l][0])/1000,4), round(avg_F, 2), round(avg_W, 2), round(avg_W_sq, 2), round(cum, 2)]
        )

        f_out.write(', '.join([str(v) for v in smd_analysed[-1]]) + '\n')

    f_out.close()

    return smd_analysed, output_type, works


def plot_pmf(smd_analysed, output='pmf', show=True, output_type='pmf', works=None):

    smd_analysed = np.array(smd_analysed)

    plt.plot(smd_analysed[:, 0], smd_analysed[:, 1])

    plt.title('Time-wise Force')
    plt.ylabel('Force')
    plt.xlabel('Time (ns)')

    plt.savefig(output + '_force_plot.png', dpi=300)

    if show:
        plt.show()
    plt.close()

    plt.plot(smd_analysed[:, 0], smd_analysed[:, 4])

    if output_type == 'pmf':
        plt.title('Time-wise PMF')
        plt.ylabel('PMF (kcal/mol)')
        plt.xlabel('Time (ns)')

        plt.savefig(output + '_plot_free_energy.png', dpi=300)
        if show:
            plt.show()
        plt.close()

        if works != None:
            works = np.array(works)

            for smd in range(len(works[0])):
                plt.plot(smd_analysed[:, 0], works[:, smd])

            plt.title('Time-wise W')
            plt.ylabel('W (kcal/mol)')
            plt.xlabel('Time (ns)')

            plt.savefig(output + '_plot_work.png', dpi=300)
            if show:
                plt.show()
            plt.close()

    if output_type == 'w':
        plt.title('Time-wise W')
        plt.ylabel('W (kcal/mol)')
        plt.xlabel('Time (ns)')

        plt.savefig(output + '_plot_work.png', dpi=300)
        if show :
            plt.show()
        plt.close()



def main():

    args = parser()

    smds = read_input_files(args.input)
    smd_analysed, output_type, works = calculate_2n_order_cumulant(smds, temp=args.temperature, output=args.output)
    #plot_pmf(smd_analysed, output=args.output, show=args.show, output_type=output_type, works=works)
    plot_pmf(smd_analysed, output=args.output, show=args.show, output_type=output_type, works=None)

    smd = np.array(smd_analysed)

    if output_type == 'pmf':
        print('Maximum PMF (kcal/mol):', np.max(smd[:,4]))
    elif output_type == 'w':
        print('Maximum W (kcal/mol):', np.max(smd[:,4]))


if __name__ == '__main__':
    main()

















