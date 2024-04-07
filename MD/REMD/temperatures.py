import math

from argparse import ArgumentParser

def parse():
    parser = ArgumentParser(description='Script for calculating the simulation temperatures of the intermediate replicas in a Replica Exchange MD simulation.')

    parser.add_argument('-t', '--min_temperature',
                        help='Temperature of the coldest replica',
                        required=False,
                        default=310.15,
                        type=float,
                       )

    parser.add_argument('-T', '--max_temperature',
                        help='Temperature of the hotest replica',
                        required=True,
                        type=float,
                       )

    parser.add_argument('-n', '--num_replicas',
                        help='Total number of replicas',
                        required=True,
                        type=int,
                       )

    parser.add_argument('-v', '--verbose',
                       help='Print all information',
                       required=False,
                       action='store_true',
                       default=False
                       )

    parser.add_argument('-nf', '--no_output_file',
                        help='Deactivates the writing of the temperatures.dat file',
                        required=False,
                        action='store_true',
                        default='False',
                       )

    parser.add_argument('-r', '--round_temperatures',
                       help='Round to units, tens or hundreds',
                       required=False,
                       default=10,
                       choices=[0, 1, 10, 100],
                       type=int
                       )

    args = parser.parse_args()

    if args.round_temperatures == 0:
        args.round_temperatures = 1
        
    elif args.round_temperatures == 1:
        args.round_temperatures = 0
        
    elif args.round_temperatures == 10:
        args.round_temperatures = -1

    elif args.round_temperatures == 100:
        args.round_temperatures = -2

    return args


def calculate_temperatures(args):
    """
    Source of equations:
        https://wikis.ch.cam.ac.uk/ro-walesdocs/wiki/index.php/REMD_with_AMBER

    DEFINITION:
        Equations for the calculation of temperatures of the intermediate replicas for a REMD simulation
    """
  
    T_max = args.max_temperature
    T_min = args.min_temperature
    n_tot = args.num_replicas
  
    A = (math.log(T_max/T_min))/(n_tot-1)

    if args.verbose:
        print('The A constant is:', A)

    temperatures = []
    for n in range(n_tot):
        if n == 0:
            temperature.append(T_min)
        elif n == n_tot-1:
            temperature.append(T_max)
        else :
            temperatures.append(round(T_min * math.e**(A*n), args.round_temperatures))

    if args.verbose or args.no_output_file:
        for n in range(n_tot):
            print(f'The temperature for replica {n+1} is ', temperatures[n])

    return temperatures

def save_temperatures(temperatures):
    """
    DEFINITION:
        Function for saving the temperatures.dat file for AmberTools genremdfiles.py
    """

    with open('temperatures.dat', 'w') as file:

        file.write("TEMPERATURE")
        file.write("Temperature Replica Exchange")
        for temperature in temperatures:
            file.write(temperature)


def main():

    args = parse()

    temperatures = calculate_temperatures(args)

    if not args.no_output_file:
        save_temperatures(temperatures)


main()

         
