```bash
traject [options] -c configuration.rb [-c config2.rb] file.mrc
    -v, --version          print version information to stderr
    -d, --debug            Include debug log, -s log.level=debug
    -h, --help             print usage information to stderr
    -c, --conf             configuration file path (repeatable)
    -s, --setting          settings: `-s key=value` (repeatable)
    -r, --reader           Set reader class, shortcut for -s reader_class_name=
    -o, --output_file      output file for Writer classes that write to files
    -w, --writer           Set writer class, shortcut for -s writer_class_name=
    -u, --solr             Set solr url, shortcut for -s solr.url=
    -t, --marc_type        xml, json or binary. shortcut for -s marc_source.type=
    -I, --load_path        append paths to ruby $LOAD_PATH
    -x, --command          alternate traject command: process (default); marcout; commit (default: process)
        --stdin            read input from stdin
```