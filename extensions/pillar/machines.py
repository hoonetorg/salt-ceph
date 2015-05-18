import os
import logging

import yaml

log = logging.getLogger(__name__)


def ext_pillar(minion_id, pillar, directory):
    '''
    Execute a command and read the output as YAML
    '''

    filename = os.path.join(directory, '%s.sls' % minion_id)
    if not os.path.exists(filename):
        return {}

    try:
        return yaml.safe_load(open(filename))
    except Exception:
        log.critical('YAML data from {0} failed to parse'.format(command))
        return {}
