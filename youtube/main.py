#!/usr/bin/env python3

from handlers import handle_link, handle_query
from parser import parse_args


def main():
    args = parse_args()
    if args.link:
        handle_link(args.link, args.save, args.resolution, args.output)
    elif args.query:
        handle_query(args.query, args.save, args.resolution, args.output)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting...")
        exit(0)
