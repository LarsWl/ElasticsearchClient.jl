using Coverage

coverage = process_folder()

LCOV.writefile("coverage/lcov.info", coverage)