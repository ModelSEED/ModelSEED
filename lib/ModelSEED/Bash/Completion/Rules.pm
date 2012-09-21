package ModelSEED::Bash::Completion::Rules;
our $rules = {
    'genome_mapping' => {
        'completions' => [
            {
                'options' => [ 'raw', 'full', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'genome_help' => {
        'completions' => [],
        'edges'       => []
    },
    'ms_whoami' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'ms_list' => {
        'completions' => [
            {
                'options' => [ 'verbose', 'mine', 'with', 'help' ],
                'prefix'  => '--'
            },
            {
                'options' =>
                  [ 'biochemistry/', 'mapping/', 'model/', 'annotation/' ],
                'prefix' => ''
            },
            {
                'cmd'    => 'ms list biochemistry',
                'prefix' => 'biochemistry/'
            },
            {
                'cmd'    => 'ms list mapping',
                'prefix' => 'mapping/'
            },
            {
                'cmd'    => 'ms list model',
                'prefix' => 'model/'
            },
            {
                'cmd'    => 'ms list annotation',
                'prefix' => 'annotation/'
            }
        ],
        'edges' => []
    },
    'mapping' => {
        'completions' => [ [ 'commands', 'readable', 'bio', 'help' ] ],
        'edges' => [
            [ 'commands', 'mapping_commands' ],
            [ 'readable', 'mapping_readable' ],
            [ 'bio',      'mapping_bio' ],
            [ 'help',     'mapping_help' ]
        ]
    },
    'genome_roles' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'bio_validate' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'model_gapgen' => {
        'completions' => [
            {
                'options' => [
                    'config',           'fbaconfig',
                    'overwrite',        'save',
                    'verbose',          'fileout',
                    'media',            'refmedia',
                    'notes',            'nomediahyp',
                    'nobiomasshyp',     'nogprhyp',
                    'nopathwayhyp',     'objective',
                    'objfraction',      'rxnko',
                    'geneko',           'uptakelim',
                    'defaultmaxflux',   'defaultmaxuptake',
                    'defaultminuptake', 'help'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'genome_readable' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'model_genome' => {
        'completions' => [
            {
                'options' => [ 'raw', 'full', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'bio_findcpd' => {
        'completions' => [
            {
                'options' => [ 'names', 'filein', 'id', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'bio_addcpd' => {
        'completions' => [
            {
                'options' => [
                    'abbreviation', 'formula',   'mass',     'charge',
                    'deltag',       'deltagerr', 'altnames', 'saveas',
                    'namespace'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'import_mapping' => {
        'completions' => [
            {
                'options' => [
                    'biochemistry', 'model', 'location', 'store',
                    'verbose',      'dry',   'help'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'stores_help' => {
        'completions' => [],
        'edges'       => []
    },
    'mapping_bio' => {
        'completions' => [
            {
                'options' => [ 'raw', 'full', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'ms_commands' => {
        'completions' => [],
        'edges'       => []
    },
    'ms_createuser' => {
        'completions' => [
            {
                'options' => [ 'firstname', 'lastname', 'email', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'model_commands' => {
        'completions' => [],
        'edges'       => []
    },
    'genome' => {
        'completions' => [
            [
                'commands',   'roles', 'readable', 'subsystems',
                'buildmodel', 'help',  'mapping'
            ]
        ],
        'edges' => [
            [ 'commands',   'genome_commands' ],
            [ 'roles',      'genome_roles' ],
            [ 'readable',   'genome_readable' ],
            [ 'subsystems', 'genome_subsystems' ],
            [ 'buildmodel', 'genome_buildmodel' ],
            [ 'help',       'genome_help' ],
            [ 'mapping',    'genome_mapping' ]
        ]
    },
    'ms_logout' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'ms' => {
        'completions' => [
            [
                'list',       'commands', 'mapping', 'config',
                'genome',     'get',      'revert',  'defaults',
                'import',     'error',    'whoami',  'history',
                'save',       'model',    'pp',      'stores',
                'help',       'login',    'bio',     'logout',
                'createuser', 'update'
            ]
        ],
        'edges' => [
            [ 'list',       'ms_list' ],
            [ 'commands',   'ms_commands' ],
            [ 'mapping',    'mapping' ],
            [ 'config',     'ms_config' ],
            [ 'genome',     'genome' ],
            [ 'get',        'ms_get' ],
            [ 'revert',     'ms_revert' ],
            [ 'defaults',   'ms_defaults' ],
            [ 'import',     'import' ],
            [ 'error',      'ms_error' ],
            [ 'whoami',     'ms_whoami' ],
            [ 'history',    'ms_history' ],
            [ 'save',       'ms_save' ],
            [ 'model',      'model' ],
            [ 'pp',         'ms_pp' ],
            [ 'stores',     'stores' ],
            [ 'help',       'ms_help' ],
            [ 'login',      'ms_login' ],
            [ 'bio',        'bio' ],
            [ 'logout',     'ms_logout' ],
            [ 'createuser', 'ms_createuser' ],
            [ 'update',     'ms_update' ]
        ]
    },
    'bio_aliasset' => {
        'completions' => [
            {
                'options' => [
                    'validate', 'list',    'store', 'verbose',
                    'dry',      'mapping', 'help'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'model_simphenotypes' => {
        'completions' => [
            {
                'options' => [
                    'save',             'saveas',
                    'verbose',          'notes',
                    'objective',        'rxnko',
                    'geneko',           'uptakelim',
                    'defaultmaxflux',   'defaultmaxuptake',
                    'defaultminuptake', 'help'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'stores_list' => {
        'completions' => [
            {
                'options' => [ 'verbose', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'genome_buildmodel' => {
        'completions' => [
            {
                'options' => [ 'mapping', 'verbose', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'bio_readable' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'ms_defaults' => {
        'completions' => [
            {
                'options' => [ 'set', 'unset', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'ms_help' => {
        'completions' => [],
        'edges'       => []
    },
    'ms_pp' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'ms_revert' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'model_sbml' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'import_annotation' => {
        'completions' => [
            {
                'options' => [
                    'list', 'source',  'store', 'verbose',
                    'dry',  'mapping', 'help'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'bio_help' => {
        'completions' => [],
        'edges'       => []
    },
    'mapping_help' => {
        'completions' => [],
        'edges'       => []
    },
    'model' => {
        'completions' => [
            [
                'gapfill',  'runfba',        'commands', 'genome',
                'readable', 'calcdistances', 'tohtml',   'simphenotypes',
                'help',     'gapgen',        'sbml'
            ]
        ],
        'edges' => [
            [ 'gapfill',       'model_gapfill' ],
            [ 'runfba',        'model_runfba' ],
            [ 'commands',      'model_commands' ],
            [ 'genome',        'model_genome' ],
            [ 'readable',      'model_readable' ],
            [ 'calcdistances', 'model_calcdistances' ],
            [ 'tohtml',        'model_tohtml' ],
            [ 'simphenotypes', 'model_simphenotypes' ],
            [ 'help',          'model_help' ],
            [ 'gapgen',        'model_gapgen' ],
            [ 'sbml',          'model_sbml' ]
        ]
    },
    'stores' => {
        'completions' =>
          [ [ 'prioritize', 'add', 'commands', 'rm', 'help', 'list' ] ],
        'edges' => [
            [ 'prioritize', 'stores_prioritize' ],
            [ 'add',        'stores_add' ],
            [ 'commands',   'stores_commands' ],
            [ 'rm',         'stores_rm' ],
            [ 'help',       'stores_help' ],
            [ 'list',       'stores_list' ]
        ]
    },
    'stores_rm' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'bio' => {
        'completions' => [
            [
                'commands',      'validate',
                'addcpd',        'addcpdtable',
                'calcdistances', 'create',
                'addrxntable',   'addrxn',
                'help',          'findcpd',
                'aliasset',      'readable'
            ]
        ],
        'edges' => [
            [ 'commands',      'bio_commands' ],
            [ 'validate',      'bio_validate' ],
            [ 'addcpd',        'bio_addcpd' ],
            [ 'addcpdtable',   'bio_addcpdtable' ],
            [ 'calcdistances', 'bio_calcdistances' ],
            [ 'create',        'bio_create' ],
            [ 'addrxntable',   'bio_addrxntable' ],
            [ 'addrxn',        'bio_addrxn' ],
            [ 'help',          'bio_help' ],
            [ 'findcpd',       'bio_findcpd' ],
            [ 'aliasset',      'bio_aliasset' ],
            [ 'readable',      'bio_readable' ]
        ]
    },
    'bio_create' => {
        'completions' => [
            {
                'options' => [ 'namespace', 'verbose' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'bio_addrxn' => {
        'completions' => [
            {
                'options' => [
                    'names',  'abbreviation', 'enzymes', 'direction',
                    'deltag', 'deltagerr',    'saveas',  'namespace'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'mapping_readable' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'stores_add' => {
        'completions' => [
            {
                'options' => [
                    'type',     'help', 'db_name', 'password',
                    'username', 'host', 'directory'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'ms_update' => {
        'completions' => [],
        'edges'       => []
    },
    'ms_login' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'ms_config' => {
        'completions' => [
            {
                'options' => [ 'list', 'remove', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'bio_addrxntable' => {
        'completions' => [
            {
                'options' => [ 'saveas', 'namespace', 'autoadd' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'ms_history' => {
        'completions' => [
            {
                'options' => [ 'date', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'ms_get' => {
        'completions' => [
            {
                'options' => [ 'file', 'pretty', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'model_gapfill' => {
        'completions' => [
            {
                'options' => [
                    'config',           'fbaconfig',
                    'overwrite',        'save',
                    'verbose',          'fileout',
                    'media',            'notes',
                    'objective',        'nomediahyp',
                    'nobiomasshyp',     'nogprhyp',
                    'nopathwayhyp',     'allowunbalanced',
                    'activitybonus',    'drainpen',
                    'directionpen',     'nostructpen',
                    'unfavorablepen',   'nodeltagpen',
                    'biomasstranspen',  'singletranspen',
                    'transpen',         'blacklistedrxns',
                    'gauranteedrxns',   'allowedcmps',
                    'objfraction',      'rxnko',
                    'geneko',           'uptakelim',
                    'defaultmaxflux',   'defaultmaxuptake',
                    'defaultminuptake', 'help'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'stores_prioritize' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'stores_commands' => {
        'completions' => [],
        'edges'       => []
    },
    'model_tohtml' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'import_biochemistry' => {
        'completions' => [
            {
                'options' =>
                  [ 'location', 'model', 'store', 'verbose', 'dry', 'help' ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'model_readable' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'genome_commands' => {
        'completions' => [],
        'edges'       => []
    },
    'bio_calcdistances' => {
        'completions' => [
            {
                'options' =>
                  [ 'verbose', 'reactions', 'roles', 'matrix', 'threshold' ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'import_model' => {
        'completions' => [
            {
                'options' => [
                    'list',    'source', 'annotation', 'store',
                    'verbose', 'dry',    'help'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'ms_error' => {
        'completions' => [
            {
                'options' => [ 'list', 'verbose', 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'import_help' => {
        'completions' => [],
        'edges'       => []
    },
    'model_runfba' => {
        'completions' => [
            {
                'options' => [
                    'config',            'overwrite',
                    'save',              'verbose',
                    'fileout',           'media',
                    'notes',             'objective',
                    'objfraction',       'rxnko',
                    'geneko',            'uptakelim',
                    'defaultmaxflux',    'defaultmaxuptake',
                    'defaultminuptake',  'fva',
                    'simulateko',        'minimizeflux',
                    'findminmedia',      'allreversible',
                    'simplethermoconst', 'thermoconst',
                    'nothermoerror',     'minthermoerror',
                    'html',              'help'
                ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'import' => {
        'completions' => [
            [
                'annotation', 'commands', 'model', 'mapping',
                'help',       'biochemistry'
            ]
        ],
        'edges' => [
            [ 'annotation',   'import_annotation' ],
            [ 'commands',     'import_commands' ],
            [ 'model',        'import_model' ],
            [ 'mapping',      'import_mapping' ],
            [ 'help',         'import_help' ],
            [ 'biochemistry', 'import_biochemistry' ]
        ]
    },
    'mapping_commands' => {
        'completions' => [],
        'edges'       => []
    },
    'model_help' => {
        'completions' => [],
        'edges'       => []
    },
    'genome_subsystems' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'bio_commands' => {
        'completions' => [],
        'edges'       => []
    },
    'import_commands' => {
        'completions' => [],
        'edges'       => []
    },
    'model_calcdistances' => {
        'completions' => [
            {
                'options' =>
                  [ 'verbose', 'reactions', 'roles', 'matrix', 'threshold' ],
                'prefix' => '--'
            }
        ],
        'edges' => []
    },
    'ms_save' => {
        'completions' => [
            {
                'options' => [ 'help' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    },
    'bio_addcpdtable' => {
        'completions' => [
            {
                'options' => [ 'saveas', 'namespace' ],
                'prefix'  => '--'
            }
        ],
        'edges' => []
    }
};
1;
