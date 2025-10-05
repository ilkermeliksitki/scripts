import argparse

def parse_args():
    parser = argparse.ArgumentParser(description='query youtube and get the relevant results.')

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-q', '--query', type=str, help='the query to search in YouTube.')
    group.add_argument('-l', '--link', type=str, help='direct YouTube link to play/download')

    parser.add_argument('-s', '--save', action='store_true', help='save the content')
    parser.add_argument('-r', '--resolution', type=int, default=540, help='the video resolution (default: 540)')
    parser.add_argument('-o', '--output', type=str, help='the location to save the content')
    args = parser.parse_args()

    return args

