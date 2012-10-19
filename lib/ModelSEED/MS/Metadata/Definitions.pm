use strict;

package ModelSEED::MS::Metadata::Definitions;

my $objectDefinitions = {};

$objectDefinitions->{FBAFormulation} = {
        parents    => ['ModelSEED::Store'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'regulatorymodel_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 0
                },
                {
                        name       => 'model_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 1
                },
                {
                        name       => 'media_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'secondaryMedia_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'fva',
                        printOrder => 10,
                        perm       => 'rw',
                        type       => 'Bool',
                        default    => 0
                },
                {
                        name       => 'comboDeletions',
                        printOrder => 11,
                        perm       => 'rw',
                        type       => 'Int',
                        default    => 0
                },
                {
                        name       => 'fluxMinimization',
                        printOrder => 12,
                        perm       => 'rw',
                        type       => 'Bool',
                        default    => 0
                },
                {
                        name       => 'findMinimalMedia',
                        printOrder => 13,
                        perm       => 'rw',
                        type       => 'Bool',
                        default    => 0
                },
                {
                        name       => 'notes',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'expressionData_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0
                },
                {
                        name       => 'objectiveConstraintFraction',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => 'none'
                },
                {
                        name       => 'allReversible',
                        printOrder => 14,
                        perm       => 'rw',
                        type       => 'Int',
                        len        => 255,
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'defaultMaxFlux',
                        printOrder => 20,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 1,
                        default    => 1000
                },
                {
                        name       => 'defaultMaxDrainFlux',
                        printOrder => 22,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 1,
                        default    => 1000
                },
                {
                        name       => 'defaultMinDrainFlux',
                        printOrder => 21,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 1,
                        default    => -1000
                },
                {
                        name       => 'maximizeObjective',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 1,
                        default    => 1
                },
                {
                        name       => 'decomposeReversibleFlux',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Bool',
                        len        => 32,
                        req        => 0,
                        default    => 0
                },
                {
                        name       => 'decomposeReversibleDrainFlux',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Bool',
                        len        => 32,
                        req        => 0,
                        default    => 0
                },
                {
                        name       => 'fluxUseVariables',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Bool',
                        len        => 32,
                        req        => 0,
                        default    => 0
                },
                {
                        name       => 'drainfluxUseVariables',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Bool',
                        len        => 32,
                        req        => 0,
                        default    => 0
                },
                {
                        name       => 'geneKO_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'reactionKO_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'parameters',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub{return {};}'
                },
                {
                        name       => 'inputfiles',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub{return {};}'
                },
                {
                        name       => 'outputfiles',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'uptakeLimits',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub{return {};}'
                },
                {
                        name       => 'numberOfSolutions',
                        printOrder => 23,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 0,
                        default    => 1
                },
                {
                        name       => 'simpleThermoConstraints',
                        printOrder => 15,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => 1
                },
                {
                        name       => 'thermodynamicConstraints',
                        printOrder => 16,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => 1
                },
                {
                        name       => 'noErrorThermodynamicConstraints',
                        printOrder => 17,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => 1
                },
                {
                        name       => 'minimizeErrorThermodynamicConstraints',
                        printOrder => 18,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => 1
                },
        ],
        subobjects => [
                {
                        name       => 'fbaObjectiveTerms',
                        printOrder => -1,
                        class      => 'FBAObjectiveTerm',
                        type       => 'encompassed'
                },
                {
                        name       => 'fbaConstraints',
                        printOrder => 1,
                        class      => 'FBAConstraint',
                        type       => 'encompassed'
                },
                {
                        name       => 'fbaReactionBounds',
                        printOrder => 2,
                        class      => 'FBAReactionBound',
                        type       => 'encompassed'
                },
                {
                        name       => 'fbaCompoundBounds',
                        printOrder => 3,
                        class      => 'FBACompoundBound',
                        type       => 'encompassed'
                },
                {
                        name       => 'fbaResults',
                        printOrder => 5,
                        class      => 'FBAResult',
                        type       => 'result'
                },
                {
                        name       => 'fbaPhenotypeSimulations',
                        printOrder => 4,
                        class      => 'FBAPhenotypeSimulation',
                        type       => 'encompassed'
                },
        ],
        links       => [
                {
                        name      => 'model',
                        attribute => 'model_link',
                        parent    => 'ModelSEED::Store',
                        method    => 'Model',
                        weak      => 0
                },
                {
                        name      => 'media',
                        attribute => 'media_link',
                        parent    => 'Biochemistry',
                        method    => 'media'
                },
                {
                        name      => 'geneKOs',
                        attribute => 'geneKO_links',
                        parent    => 'Annotation',
                        method    => 'features',
                        array     => 1
                },
                {
                        name      => 'reactionKOs',
                        attribute => 'reactionKO_links',
                        parent    => 'Biochemistry',
                        method    => 'reactions',
                        array     => 1
                },
                {
                        name      => 'secondaryMedia',
                        attribute => 'secondaryMedia_links',
                        parent    => 'Biochemistry',
                        method    => 'media',
                        array     => 1
                },
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{FBAConstraint} = {
        parents    => ['FBAFormulation'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'name',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'rhs',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'sign',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => '0'
                }
        ],
        subobjects => [
                {
                        name       => 'fbaConstraintVariables',
                        printOrder => -1,
                        class      => 'FBAConstraintVariable',
                        type       => 'encompassed'
                },
        ],
        links       => []
};

$objectDefinitions->{FBAConstraintVariable} = {
        parents    => ['FBAConstraint'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'entity_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'entityType',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'variableType',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'coefficient',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
        ],
        subobjects  => [],
        links       => []
};

$objectDefinitions->{FBAReactionBound} = {
        parents    => ['FBAFormulation'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'modelreaction_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'variableType',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'upperBound',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
                {
                        name       => 'lowerBound',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'modelReaction',
                        attribute => 'modelreaction_link',
                        parent    => 'Model',
                        method    => 'modelreactions'
                },
        ]
};

$objectDefinitions->{FBACompoundBound} = {
        parents    => ['FBAFormulation'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'modelcompound_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'variableType',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'upperBound',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
                {
                        name       => 'lowerBound',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'modelCompound',
                        attribute => 'modelcompound_link',
                        parent    => 'Model',
                        method    => 'modelcompounds'
                },
        ]
};

$objectDefinitions->{FBAPhenotypeSimulation} = {
        parents    => ['FBAFormulation'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'label',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'pH',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
                {
                        name       => 'temperature',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
                {
                        name       => 'additionalCpd_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 1,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'geneKO_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_links]',
                        req        => 1,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'reactionKO_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_links]',
                        req        => 1,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'media_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'observedGrowthFraction',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'media',
                        attribute => 'media_link',
                        parent    => 'Biochemistry',
                        method    => 'media'
                },
                {
                        name      => 'geneKOs',
                        attribute => 'geneKO_links',
                        parent    => 'Annotation',
                        method    => 'features',
                        array     => 1
                },
                {
                        name      => 'reactionKOs',
                        attribute => 'reactionKO_links',
                        parent    => 'Biochemistry',
                        method    => 'reactions',
                        array     => 1
                },
                {
                        name      => 'additionalCpds',
                        attribute => 'additionalCpd_links',
                        parent    => 'Biochemistry',
                        method    => 'compounds',
                        array     => 1
                },
        ]
};

$objectDefinitions->{FBAObjectiveTerm} = {
        parents    => ['FBAFormulation'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'entity_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'entityType',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'variableType',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'coefficient',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
        ],
        subobjects  => [],
        links       => []
};

$objectDefinitions->{FBAResult} = {
        parents    => ['FBAFormulation'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'notes',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'objectiveValue',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'outputfiles',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub{return {};}'
                },
        ],
        subobjects => [
                {
                        name       => 'fbaCompoundVariables',
                        printOrder => 2,
                        class      => 'FBACompoundVariable',
                        type       => 'encompassed'
                },
                {
                        name       => 'fbaReactionVariables',
                        printOrder => 3,
                        class      => 'FBAReactionVariable',
                        type       => 'encompassed'
                },
                {
                        name       => 'fbaBiomassVariables',
                        printOrder => 1,
                        class      => 'FBABiomassVariable',
                        type       => 'encompassed'
                },
                {
                        name       => 'fbaPhenotypeSimultationResults',
                        printOrder => 6,
                        class      => 'FBAPhenotypeSimultationResult',
                        type       => 'encompassed'
                },
                {
                        name       => 'fbaDeletionResults',
                        printOrder => 4,
                        class      => 'FBADeletionResult',
                        type       => 'encompassed'
                },
                {
                        name       => 'minimalMediaResults',
                        printOrder => 5,
                        class      => 'FBAMinimalMediaResult',
                        type       => 'encompassed'
                },
                {
                        name       => 'fbaMetaboliteProductionResults',
                        printOrder => 0,
                        class      => 'FBAMetaboliteProductionResult',
                        type       => 'encompassed'
                }
        ],
        links              => [],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{FBACompoundVariable} = {
        parents    => ['FBAResult'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'modelcompound_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'variableType',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'class',
                        printOrder => 9,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'lowerBound',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'upperBound',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'min',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'max',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'value',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'modelcompound',
                        attribute => 'modelcompound_link',
                        parent    => 'Model',
                        method    => 'modelcompounds'
                },
        ]
};

$objectDefinitions->{FBABiomassVariable} = {
        parents    => ['FBAResult'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'biomass_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'variableType',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'class',
                        printOrder => 9,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'lowerBound',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'upperBound',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'min',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'max',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'value',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'biomass',
                        attribute => 'biomass_link',
                        parent    => 'Model',
                        method    => 'biomasses'
                },
        ]
};

$objectDefinitions->{FBAReactionVariable} = {
        parents    => ['FBAResult'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'modelreaction_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'variableType',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'class',
                        printOrder => 9,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'lowerBound',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'upperBound',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'min',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'max',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'value',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Num',
                        len        => 1,
                        req        => 0
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'modelreaction',
                        attribute => 'modelreaction_link',
                        parent    => 'Model',
                        method    => 'modelreactions'
                },
        ]
};

$objectDefinitions->{FBAPhenotypeSimultationResult} = {
        parents    => ['FBAResult'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'simulatedGrowthFraction',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
                {
                        name       => 'simulatedGrowth',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
                {
                        name       => 'class',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 1,
                        req        => 1
                },
                {
                        name       => 'noGrowthCompounds',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'dependantReactions',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'dependantGenes',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'fluxes',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub{return {};}'
                },
                {
                        name       => 'fbaPhenotypeSimulation_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'fbaPhenotypeSimulation',
                        attribute => 'fbaPhenotypeSimulation_link',
                        parent    => 'FBAFormulation',
                        method    => 'fbaPhenotypeSimulations'
                },
        ]
};

$objectDefinitions->{FBADeletionResult} = {
        parents    => ['FBAResult'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'geneko_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 1
                },
                {
                        name       => 'growthFraction',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'genekos',
                        attribute => 'geneko_links',
                        parent    => 'Annotation',
                        method    => 'features',
                        array     => 1
                },
        ]
};

$objectDefinitions->{FBAMinimalMediaResult} = {
        parents    => ['FBAResult'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'minimalMedia_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'essentialNutrient_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 1
                },
                {
                        name       => 'optionalNutrient_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'minimalMedia',
                        attribute => 'minimalMedia_link',
                        parent    => 'Biochemistry',
                        method    => 'media'
                },
                {
                        name      => 'essentialNutrients',
                        attribute => 'essentialNutrient_links',
                        parent    => 'Biochemistry',
                        method    => 'compounds',
                        array     => 1
                },
                {
                        name      => 'optionalNutrients',
                        attribute => 'optionalNutrient_links',
                        parent    => 'Biochemistry',
                        method    => 'compounds',
                        array     => 1
                }
        ]
};

$objectDefinitions->{FBAMetaboliteProductionResult} = {
        parents    => ['FBAResult'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'modelCompound_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'maximumProduction',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'modelCompound',
                        attribute => 'modelCompound_link',
                        parent    => 'Model',
                        method    => 'modelcompounds'
                },
        ]
};

$objectDefinitions->{GapgenFormulation} = {
        parents    => ['ModelSEED::Store'],
        class      => 'parent',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'fbaFormulation_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 0
                },
                {
                        name       => 'model_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 1
                },
                {
                        name       => 'mediaHypothesis',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'biomassHypothesis',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'gprHypothesis',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'reactionRemovalHypothesis',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'referenceMedia_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                }
        ],
        subobjects => [
                {
                        name       => 'gapgenSolutions',
                        printOrder => 0,
                        class      => 'GapgenSolution',
                        type       => 'encompassed'
                }
        ],
        links       => [
                {
                        name      => 'model',
                        attribute => 'model_link',
                        parent    => 'ModelSEED::Store',
                        method    => 'Model',
                        weak      => 0
                },
                {
                        name      => 'fbaFormulation',
                        attribute => 'fbaFormulation_link',
                        parent    => 'ModelSEED::Store',
                        method    => 'FBAFormulation',
                        weak      => 0
                },
                {
                        name      => 'referenceMedia',
                        attribute => 'referenceMedia_link',
                        parent    => 'Biochemistry',
                        method    => 'media'
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{GapgenSolution} = {
        parents    => ['GapgenFormulation'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'solutionCost',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'biomassSupplement_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'mediaRemoval_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'additionalKO_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
        ],
        subobjects => [
                {
                        name  => 'gapgenSolutionReactions',
                        class => 'GapgenSolutionReaction',
                        type  => 'encompassed'
                },
        ],
        links       => [
                {
                        name      => 'biomassSupplements',
                        attribute => 'biomassSupplement_links',
                        parent    => 'Model',
                        method    => 'modelcompounds',
                        array     => 1
                },
                {
                        name      => 'mediaRemovals',
                        attribute => 'mediaRemoval_links',
                        parent    => 'Model',
                        method    => 'modelcompounds',
                        array     => 1
                },
                {
                        name      => 'additionalKOs',
                        attribute => 'additionalKO_links',
                        parent    => 'Model',
                        method    => 'modelreactions',
                        array     => 1
                },
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{GapgenSolutionReaction} = {
        parents    => ['GapgenSolution'],
        class      => 'child',
        attributes => [
                {
                        name       => 'modelreaction_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'direction',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => '1'
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'modelreaction',
                        attribute => 'modelreaction_link',
                        parent    => 'Model',
                        method    => 'modelreactions'
                },
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{GapfillingFormulation} = {
        parents    => ['ModelSEED::Store'],
        class      => 'parent',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'fbaFormulation_link',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 0
                },
                {
                        name       => 'model_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 1
                },
                {
                        name       => 'mediaHypothesis',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'biomassHypothesis',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'gprHypothesis',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'reactionAdditionHypothesis',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'balancedReactionsOnly',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'guaranteedReaction_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_links]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'blacklistedReaction_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_links]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'allowableCompartment_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_links]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'reactionActivationBonus',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'drainFluxMultiplier',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'directionalityMultiplier',
                        printOrder => 9,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'deltaGMultiplier',
                        printOrder => 10,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'noStructureMultiplier',
                        printOrder => 11,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'noDeltaGMultiplier',
                        printOrder => 12,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'biomassTransporterMultiplier',
                        printOrder => 13,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'singleTransporterMultiplier',
                        printOrder => 14,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'transporterMultiplier',
                        printOrder => 15,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                }
        ],
        subobjects => [
                {
                        name  => 'gapfillingGeneCandidates',
                        class => 'GapfillingGeneCandidate',
                        type  => 'encompassed'
                },
                {
                        name  => 'reactionSetMultipliers',
                        class => 'ReactionSetMultiplier',
                        type  => 'encompassed'
                },
                {
                        name       => 'gapfillingSolutions',
                        printOrder => 0,
                        class      => 'GapfillingSolution',
                        type       => 'encompassed'
                }
        ],
        links       => [
                {
                        name      => 'model',
                        attribute => 'model_link',
                        parent    => 'ModelSEED::Store',
                        method    => 'Model',
                        weak      => 0
                },
                {
                        name      => 'fbaFormulation',
                        attribute => 'fbaFormulation_link',
                        parent    => 'ModelSEED::Store',
                        method    => 'FBAFormulation',
                        weak      => 0
                },
                {
                        name      => 'guaranteedReactions',
                        attribute => 'guaranteedReaction_links',
                        parent    => 'Biochemistry',
                        method    => 'reactions',
                        array     => 1
                },
                {
                        name      => 'blacklistedReactions',
                        attribute => 'blacklistedReaction_links',
                        parent    => 'Biochemistry',
                        method    => 'reactions',
                        array     => 1
                },
                {
                        name      => 'allowableCompartments',
                        attribute => 'allowableCompartment_links',
                        parent    => 'Biochemistry',
                        method    => 'compartments',
                        array     => 1
                }
        ],
        reference_id_types => [qw(uid)]
};

$objectDefinitions->{GapfillingSolution} = {
        parents    => ['GapfillingFormulation'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'solutionCost',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'biomassRemoval_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'mediaSupplement_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'koRestore_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
        ],
        subobjects => [
                {
                        name  => 'gapfillingSolutionReactions',
                        class => 'GapfillingSolutionReaction',
                        type  => 'encompassed'
                },
        ],
        links       => [
                {
                        name      => 'biomassRemovals',
                        attribute => 'biomassRemoval_links',
                        parent    => 'Model',
                        method    => 'modelcompounds',
                        array     => 1
                },
                {
                        name      => 'mediaSupplements',
                        attribute => 'mediaSupplement_links',
                        parent    => 'Model',
                        method    => 'modelcompounds',
                        array     => 1
                },
                {
                        name      => 'koRestores',
                        attribute => 'koRestore_links',
                        parent    => 'Model',
                        method    => 'modelreactions',
                        array     => 1
                },
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{GapfillingSolutionReaction} = {
        parents    => ['GapfillingSolution'],
        class      => 'child',
        attributes => [
                {
                        name       => 'reaction_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'compartment_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'direction',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'candidateFeature_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
        ],
        subobjects => [],
        links       => [
                {
                        name      => 'reaction',
                        attribute => 'reaction_link',
                        parent    => 'Biochemistry',
                        method    => 'reactions'
                },
                {
                        name      => 'compartment',
                        attribute => 'compartment_link',
                        parent    => 'Biochemistry',
                        method    => 'compartments'
                },
                {
                        name      => 'candidateFeatures',
                        attribute => 'candidateFeature_links',
                        parent    => 'Annotation',
                        method    => 'features',
                        array     => 1
                },
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{GapfillingGeneCandidate} = {
        parents    => ['GapfillingFormulation'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'feature_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0
                },
                {
                        name       => 'ortholog_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0
                },
                {
                        name       => 'orthologGenome_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0
                },
                {
                        name       => 'similarityScore',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'distanceScore',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'role_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'feature',
                        attribute => 'feature_link',
                        parent    => 'Annotation',
                        method    => 'features'
                },
                {
                        name      => 'ortholog',
                        attribute => 'ortholog_link',
                        parent    => 'Annotation',
                        method    => 'features'
                },
                {
                        name      => 'orthologGenome',
                        attribute => 'orthogenome_link',
                        parent    => 'Annotation',
                        method    => 'genomes'
                },
                {
                        name      => 'role',
                        attribute => 'role_link',
                        parent    => 'Mapping',
                        method    => 'roles'
                }
        ]
};

$objectDefinitions->{ReactionSetMultiplier} = {
        parents    => ['GapfillingFormulation'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'reactionset_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0
                },
                {
                        name       => 'reactionsetType',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'multiplierType',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'description',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'multiplier',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'reactionset',
                        attribute => 'reactionset_link',
                        parent    => 'Biochemistry',
                        method    => 'reactionSets'
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{User} = {
        parents    => ['ModelSEED::Store'],
        class      => 'parent',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'login',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'password',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'email',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'firstname',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'lastname',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                },
        ],
        subobjects         => [],
        links              => [],
        reference_id_types => [qw(uid)],
        version            => 1.0,
};

$objectDefinitions->{BiochemistryStructures} = {
        parents    => ['ModelSEED::Store'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0,
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                }
        ],
        subobjects => [
                {
                        name       => 'structures',
                        printOrder => 0,
                        class      => 'Structure',
                        type       => 'child'
                }
        ],
        links              => [],
        reference_id_types => [qw(uid alias)],
        version            => 1.0,
};

$objectDefinitions->{Structure} = {
        parents    => ['BiochemistryStructures'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0,
                },
                {
                        name       => 'data',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'cksum',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'type',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 1
                }
        ],
        subobjects  => [],
        links       => [],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{AliasSet} = {
        parents    => ['Ref'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },    #KEGG, GenBank, SEED, ModelSEED
                {
                        name       => 'source',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },    #url or pubmed ID indicating where the alias set came from
                {
                        name       => 'class',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },    #
                {
                        name       => 'attribute',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },    #
                {
                        name       => 'aliases',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub {return {};}'
                }     #url or pubmed ID indicating where the alias set came from
        ],
        subobjects         => [],
        links              => [],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{Biochemistry} = {
        parents    => ['ModelSEED::Store'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0,
                },
                {
                        name       => 'defaultNameSpace',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 0,
                        default    => 'ModelSEED',
                        description =>
'The name of an [[AliasSet|#wiki-AliasSet]] to use in aliasSets for reaction and compound ids',
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                },
                {
                        name       => 'name',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'biochemistryStructures_link',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 0,
                },
                {
                        name       => 'forwardedLinks',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub {return {};}'
                }
        ],
        subobjects => [
                {
                        name       => 'compartments',
                        printOrder => 0,
                        class      => 'Compartment',
                        type       => 'child'
                },
                {
                        name       => 'compounds',
                        printOrder => 3,
                        class      => 'Compound',
                        type       => 'child'
                },
                {
                        name       => 'reactions',
                        printOrder => 4,
                        class      => 'Reaction',
                        type       => 'child'
                },
                {
                        name       => 'media',
                        printOrder => 2,
                        class      => 'Media',
                        type       => 'child'
                },
                {
                        name  => 'compoundSets',
                        class => 'CompoundSet',
                        type  => 'child'
                },
                {
                        name  => 'reactionSets',
                        class => 'ReactionSet',
                        type  => 'child'
                },
                {
                        name  => 'aliasSets',
                        class => 'AliasSet',
                        type  => 'child'
                },
                {
                        name        => 'cues',
                        printOrder  => 1,
                        class       => 'Cue',
                        type        => 'encompassed',
                        description => 'Structural cues for parts of compund structures',
                },
        ],
        links              => [
                {
                        name      => 'biochemistrystructures',
                        attribute => 'biochemistryStructures_link',
                        parent    => 'ModelSEED::Store',
                        method    => 'BiochemistryStructures',
                        weak      => 0
                }
        ],
        reference_id_types => [qw(uid alias)],
        version            => 2.0,
};

$objectDefinitions->{AliasSet} = {
        parents    => ['Ref'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },    #KEGG, GenBank, SEED, ModelSEED
                {
                        name       => 'source',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },    #url or pubmed ID indicating where the alias set came from
                {
                        name       => 'class',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },    #
                {
                        name       => 'attribute',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },    #
                {
                        name       => 'aliases',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub {return {};}'
                }     #url or pubmed ID indicating where the alias set came from
        ],
        subobjects         => [],
        links              => [],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{Compartment} = {
        parents    => ['Biochemistry'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        len        => 36,
                        req        => 1,
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                },
                {
                        name       => 'id',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 2,
                        req        => 1,
                        description =>
'Single charachter identifer for the compartment, e.g. "e" or "c".',
                },
                {
                        name       => 'name',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => '',
                },
                {
                        name       => 'hierarchy',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 0,
                        default    => '',
                        description =>
'Index indicating the position of a compartment relative to other compartments. Extracellular is 0. A compartment contained within another compartment has an index that is +1 over the outer comaprtment.',
                },
        ],
        subobjects         => [],
        links              => [],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{Cue} = {
        parents    => ['Biochemistry'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        len        => 36,
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'abbreviation',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'cksum',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'unchargedFormula',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'formula',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'mass',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'defaultCharge',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'deltaG',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'deltaGErr',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'smallMolecule',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0
                },
                {
                        name       => 'priority',
                        printOrder => 9,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 0
                },
                {
                        name       => 'structure_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0
                }
        ],
        subobjects => [],
        links              => [
                {
                        name      => 'structure',
                        attribute => 'structure_link',
                        parent    => 'BiochemistryStructures',
                        method    => 'structures',
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{Compound} = {
        alias      => 'Biochemistry',
        parents    => ['Biochemistry'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        len        => 36,
                        req        => 0
                },
                {
                        name       => 'isCofactor',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Bool',
                        default    => '0',
                        req        => 0,
                        description =>
'A boolean indicating if this compound is a universal cofactor (e.g. water/H+).',
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'abbreviation',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'cksum',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => '',
                        description =>
                          'A computed hash for the compound, not currently implemented',
                },
                {
                        name       => 'unchargedFormula',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => '',
                        description =>
                          'Formula for compound if it does not have a ionic charge.',
                },
                {
                        name        => 'formula',
                        printOrder  => 3,
                        perm        => 'rw',
                        type        => 'ModelSEED::varchar',
                        req         => 0,
                        default     => '',
                        description => 'Formula for the compound at pH 7.',
                },
                {
                        name        => 'mass',
                        printOrder  => 4,
                        perm        => 'rw',
                        type        => 'Num',
                        req         => 0,
                        description => 'Atomic mass of the compound',
                },
                {
                        name        => 'defaultCharge',
                        printOrder  => 5,
                        perm        => 'rw',
                        type        => 'Num',
                        req         => 0,
                        default     => 0,
                        description => 'Computed charge for compound at pH 7.',
                },
                {
                        name       => 'deltaG',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        description =>
                          'Computed Gibbs free energy value for compound at pH 7.',
                },
                {
                        name       => 'deltaGErr',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        description =>
                          'Error bound on Gibbs free energy compoutation for compound.',
                },
                {
                        name       => 'abstractCompound_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0,
                        description => 'Reference to abstract compound of which this compound is a specific class.',
                },
                {
                        name       => 'comprisedOfCompound_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        description => 'Array of references to subcompounds that this compound is comprised of.',
                },
                {
                        name       => 'structure_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        description => 'Array of associated molecular structures',
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'cues',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        description => 'Hash of cue uuids with cue coefficients as values',
                        default    => 'sub{return {};}'
                },
                {
                        name       => 'pkas',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        description => 'Hash of pKa values with atom numbers as values',
                        default    => 'sub{return {};}'
                },
                {
                        name       => 'pkbs',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        description => 'Hash of pKb values with atom numbers as values',
                        default    => 'sub{return {};}'
                }
        ],
        subobjects => [],
        links       => [
                {
                        name      => 'abstractCompound',
                        attribute => 'abstractCompound_link',
                        parent    => 'Biochemistry',
                        method    => 'compounds',
            can_be_undef => 1,
                },
                {
                        name      => 'comprisedOfCompounds',
                        attribute => 'comprisedOfCompound_links',
                        parent    => 'Biochemistry',
                        method    => 'compounds',
                        array     => 1
                },
                {
                        name      => 'structures',
                        attribute => 'structure_links',
                        parent    => 'BiochemistryStructures',
                        method    => 'structures',
                        array     => 1
                }
        ],
        reference_id_types => [qw(uid)]
};

$objectDefinitions->{Reaction} = {
        alias      => 'Biochemistry',
        parents    => ['Biochemistry'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        len        => 36,
                        req        => 0,
                        description => 'Universal ID for reaction'
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name      => 'name',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'abbreviation',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'cksum',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'deltaG',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'deltaGErr',
                        printOrder => 9,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'direction',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 1,
                        req        => 0,
                        default    => '='
                },
                {
                        name       => 'thermoReversibility',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 1,
                        req        => 0
                },
                {
                        name       => 'defaultProtons',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'status',
                        printOrder => 10,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'cues',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub{return {};}'
                },
                {
                        name       => 'abstractReaction_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0,
                        description => 'Reference to abstract reaction of which this reaction is an example.'
                },
        ],
        subobjects => [
                {
                        name  => 'reagents',
                        class => 'Reagent',
                        type  => 'encompassed'
                },
        ],
        links       => [
                {
                        name      => 'abstractReaction',
                        attribute => 'abstractReaction_link',
                        parent    => 'Biochemistry',
                        method    => 'reactions',
                        can_be_undef => 1,
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{Reagent} = {
        parents    => ['Reaction'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'compound_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        len        => 36,
                        req        => 1
                },
                {
                        name       => 'compartment_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        len        => 36,
                        req        => 1
                },
                {
                        name       => 'coefficient',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
                {
                        name       => 'isCofactor',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'compound',
                        attribute => 'compound_link',
                        parent    => 'Biochemistry',
                        method    => 'compounds'
                },
                {
                        name      => 'compartment',
                        attribute => 'compartment_link',
                        parent    => 'Biochemistry',
                        method    => 'compartments'
                },
        ]
};

$objectDefinitions->{Media} = {
        parents    => ['Biochemistry'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'isDefined',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'isMinimal',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'id',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 1
                },
                {
                        name       => 'name',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'type',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 1,
                        req        => 0,
                        default    => 'unknown'
                },
        ],
        subobjects => [
                {
                        name  => 'mediacompounds',
                        class => 'MediaCompound',
                        type  => 'encompassed'
                },
        ],
        links              => [],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{MediaCompound} = {
        parents    => ['Media'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'compound_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'concentration',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0.001'
                },
                {
                        name       => 'maxFlux',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '100'
                },
                {
                        name       => 'minFlux',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '-100'
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'compound',
                        attribute => 'compound_link',
                        parent    => 'Biochemistry',
                        method    => 'compounds'
                },
        ]
};

$objectDefinitions->{CompoundSet} = {
        parents    => ['Biochemistry'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'id',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 1
                },
                {
                        name       => 'name',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'class',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => 'unclassified'
                },
                {
                        name       => 'type',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 1
                },
                {
                        name       => 'compound_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
        ],
        subobjects => [],
        links              => [
                {
                        name      => 'compounds',
                        attribute => 'compound_links',
                        parent    => 'Biochemistry',
                        method    => 'compounds',
                        array     => 1
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{ReactionSet} = {
        parents    => ['Biochemistry'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'id',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 1
                },
                {
                        name       => 'name',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'class',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => 'unclassified'
                },
                {
                        name       => 'type',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 1
                },
                {
                        name       => 'reaction_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
        ],
        subobjects => [],
        links              => [
                {
                        name      => 'reactions',
                        attribute => 'reaction_links',
                        parent    => 'Biochemistry',
                        method    => 'reactions',
                        array     => 1
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{Model} = {
        parents    => ['ModelSEED::Store'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'defaultNameSpace',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 0,
                        default    => 'ModelSEED'
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'id',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 1
                },
                {
                        name       => 'name',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'version',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'type',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 0,
                        default    => 'Singlegenome'
                },
                {
                        name       => 'status',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 0
                },
                {
                        name       => 'growth',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'current',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'mapping_link',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 0
                },
                {
                        name       => 'biochemistry_link',
                        printOrder => 9,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 1
                },
                {
                        name       => 'annotation_link',
                        printOrder => 10,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 0
                },
                {
                        name       => 'fbaFormulation_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::provenance_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'integratedGapfilling_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::provenance_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'integratedGapfillingSolutions',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub{return {};}'
                },
                {
                        name       => 'unintegratedGapfilling_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::provenance_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'integratedGapgen_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::provenance_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'unintegratedGapgen_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::provenance_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
                {
                        name       => 'forwardedLinks',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub {return {};}'
                }
        ],
        subobjects => [
                {
                        name       => 'biomasses',
                        printOrder => 0,
                        class      => 'Biomass',
                        type       => 'child'
                },
                {
                        name       => 'modelcompartments',
                        printOrder => 1,
                        class      => 'ModelCompartment',
                        type       => 'child'
                },
                {
                        name       => 'modelcompounds',
                        printOrder => 2,
                        class      => 'ModelCompound',
                        type       => 'child'
                },
                {
                        name       => 'modelreactions',
                        printOrder => 3,
                        class      => 'ModelReaction',
                        type       => 'child'
                }
        ],
        links       => [
                {
                        name      => 'fbaFormulations',
                        attribute => 'fbaFormulation_links',
                        parent    => 'ModelSEED::Store',
                        method    => 'FBAFormulation',
                        array     => 1
                },
                {
                        name      => 'unintegratedGapfillings',
                        attribute => 'unintegratedGapfilling_links',
                        parent    => 'ModelSEED::Store',
                        method    => 'GapfillingFormulation',
                        array     => 1
                },
                {
                        name      => 'integratedGapfillings',
                        attribute => 'integratedGapfilling_links',
                        parent    => 'ModelSEED::Store',
                        method    => 'GapfillingFormulation',
                        array     => 1
                },
                {
                        name      => 'unintegratedGapgens',
                        attribute => 'unintegratedGapgen_links',
                        parent    => 'ModelSEED::Store',
                        method    => 'GapgenFormulation',
                        array     => 1
                },
                {
                        name      => 'integratedGapgens',
                        attribute => 'integratedGapgen_links',
                        parent    => 'ModelSEED::Store',
                        method    => 'GapgenFormulation',
                        array     => 1
                },
                {
                        name      => 'biochemistry',
                        attribute => 'biochemistry_links',
                        parent    => 'ModelSEED::Store',
                        method    => 'Biochemistry',
                        weak      => 0
                },
                {
                        name      => 'mapping',
                        attribute => 'mapping_links',
                        parent    => 'ModelSEED::Store',
                        method    => 'Mapping',
                        weak      => 0
                },
                {
                        name      => 'annotation',
                        attribute => 'annotation_links',
                        parent    => 'ModelSEED::Store',
                        method    => 'Annotation',
                        weak      => 0
                }
        ],
        reference_id_types => [qw(uid alias)],
        version            => 2.0,
};

$objectDefinitions->{Biomass} = {
        alias      => 'Model',
        parents    => ['Model'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'dna',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0.05'
                },
                {
                        name       => 'rna',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0.1'
                },
                {
                        name       => 'protein',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0.5'
                },
                {
                        name       => 'cellwall',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0.15'
                },
                {
                        name       => 'lipid',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0.05'
                },
                {
                        name       => 'cofactor',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0.15'
                },
                {
                        name       => 'energy',
                        printOrder => 9,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '40'
                },
        ],
        subobjects => [
                {
                        name  => 'biomasscompounds',
                        class => 'BiomassCompound',
                        type  => 'encompassed'
                }
        ],
        links              => [],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{BiomassCompound} = {
        parents    => ['Biomass'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'modelcompound_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'coefficient',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'modelcompound',
                        attribute => 'modelcompound_link',
                        parent    => 'Model',
                        method    => 'modelcompounds'
                },
        ]
};

$objectDefinitions->{ModelCompartment} = {
        parents    => ['Model'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'compartment_link',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'compartmentIndex',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 1
                },
                {
                        name       => 'label',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'pH',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '7'
                },
                {
                        name       => 'potential',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'compartment',
                        attribute => 'compartment_link',
                        parent    => 'Biochemistry',
                        method    => 'compartments'
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{ModelCompound} = {
        parents    => ['Model'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'compound_link',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'charge',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'formula',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'modelcompartment_link',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'compound',
                        attribute => 'compound_link',
                        parent    => 'Biochemistry',
                        method    => 'compounds'
                },
                {
                        name      => 'modelcompartment',
                        attribute => 'modelcompartment_link',
                        parent    => 'Model',
                        method    => 'modelcompartments'
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{ModelReaction} = {
        parents    => ['Model'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'reaction_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'direction',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 1,
                        req        => 0,
                        default    => '='
                },
                {
                        name       => 'protons',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => 0
                },
                {
                        name       => 'modelcompartment_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
        ],
        subobjects => [
                {
                        name  => 'modelReactionProteins',
                        class => 'ModelReactionProtein',
                        type  => 'encompassed'
                },
                {
                        name  => 'modelReactionReagents',
                        class => 'ModelReactionReagent',
                        type  => 'encompassed'
                },
        ],
        links       => [
                {
                        name      => 'reaction',
                        attribute => 'reaction_link',
                        parent    => 'Biochemistry',
                        method    => 'reactions'
                },
                {
                        name      => 'modelcompartment',
                        attribute => 'modelcompartment_link',
                        parent    => 'Model',
                        method    => 'modelcompartments'
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{ModelReactionReagent} = {
        parents    => ['ModelReaction'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'modelcompound_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        len        => 36,
                        req        => 1
                },
                {
                        name       => 'coefficient',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'modelcompound',
                        attribute => 'modelcompound_link',
                        parent    => 'Model',
                        method    => 'modelcompounds'
                }
        ]
};

$objectDefinitions->{ModelReactionProtein} = {
        parents    => ['ModelReaction'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'complex_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'note',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                }
        ],
        subobjects => [
                {
                        name  => 'modelReactionProteinSubunits',
                        class => 'ModelReactionProteinSubunit',
                        type  => 'encompassed'
                },
        ],
        links       => [
                {
                        name      => 'complex',
                        attribute => 'complex_link',
                        parent    => 'Mapping',
                        method    => 'complexes'
                }
        ]
};

$objectDefinitions->{ModelReactionProteinSubunit} = {
        parents    => ['ModelReactionProtein'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'role_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'triggering',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '1'
                },
                {
                        name       => 'optional',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Bool',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'note',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                },
        ],
        subobjects => [
                {
                        name  => 'modelReactionProteinSubunitGenes',
                        class => 'ModelReactionProteinSubunitGene',
                        type  => 'encompassed'
                },
        ],
        links       => [
                {
                        name      => 'role',
                        attribute => 'role_link',
                        parent    => 'Mapping',
                        method    => 'roles'
                }
        ]
};

$objectDefinitions->{ModelReactionProteinSubunitGene} = {
        parents    => ['ModelReactionProteinSubunit'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'feature_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'feature',
                        attribute => 'feature_link',
                        parent    => 'Annotation',
                        method    => 'features'
                }
        ]
};

$objectDefinitions->{Annotation} = {
        parents    => ['ModelSEED::Store'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'defaultNameSpace',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 0,
                        default    => 'SEED'
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'mapping_link',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link'
                },
                {
                        name       => 'forwardedLinks',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub {return {};}'
                }
        ],
        subobjects => [
                {
                        name       => 'genomes',
                        printOrder => 0,
                        class      => 'Genome',
                        type       => 'child'
                },
                {
                        name       => 'features',
                        printOrder => 1,
                        class      => 'Feature',
                        type       => 'child'
                },
                {
                        name       => 'subsystemStates',
                        printOrder => 2,
                        class      => 'SubsystemState',
                        type       => 'child'
                },
        ],
        links       => [
                {
                        name      => 'mapping',
                        attribute => 'mapping_link',
                        parent    => 'ModelSEED::Store',
                        method    => 'Mapping',
                        weak      => 0
                },
        ],
        reference_id_types => [qw(uid alias)],
        version            => 1.0,
};

$objectDefinitions->{Genome} = {
        parents    => ['Annotation'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'id',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 1
                },
                {
                        name       => 'name',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'source',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 1
                },
                {
                        name       => 'class',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },    #gramPositive,gramNegative,archaea,eurkaryote
                {
                        name       => 'taxonomy',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'cksum',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'size',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 0
                },
                {
                        name       => 'gc',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0
                },
                {
                        name       => 'etcType',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        len        => 1,
                        req        => 0
                },    #aerobe,facultativeAnaerobe,obligateAnaerobe
        ],
        subobjects         => [],
        links              => [],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{Feature} = {
        parents    => ['Annotation'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'id',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 1
                },
                {
                        name       => 'cksum',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'genome_link',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'start',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 0
                },
                {
                        name       => 'stop',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 0
                },
                {
                        name       => 'contig',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'direction',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'sequence',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'type',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
        ],
        subobjects => [
                {
                        name  => 'featureroles',
                        class => 'FeatureRole',
                        type  => 'encompassed'
                },
        ],
        links       => [
                {
                        name      => 'genome',
                        attribute => 'genome_link',
                        parent    => 'Annotation',
                        method    => 'genomes'
                },
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{FeatureRole} = {
        parents    => ['Feature'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'role_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'compartment',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        default    => 'unknown'
                },
                {
                        name       => 'comment',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        default    => ''
                },
                {
                        name       => 'delimiter',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        default    => ''
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'role',
                        attribute => 'role_link',
                        parent    => 'Mapping',
                        method    => 'roles'
                },
        ]
};

$objectDefinitions->{SubsystemState} = {
        parents    => ['Annotation'],
        class      => 'child',
        attributes => [
                {
                        name       => 'roleset_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'variant',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                }
        ],
        subobjects         => [],
        links              => [
                {
                        name      => 'roleset',
                        attribute => 'roleset_link',
                        parent    => 'Mapping',
                        method    => 'rolesets'

                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{Mapping} = {
        parents    => ['ModelSEED::Store'],
        class      => 'indexed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'defaultNameSpace',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 0,
                        default    => 'SEED'
                },
                {
                        name       => 'biochemistry_link',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'ModelSEED::provenance_link',
                        req        => 0
                },
                {
                        name       => 'forwardedLinks',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'HashRef',
                        req        => 0,
                        default    => 'sub {return {};}'
                }
        ],
        subobjects => [
                {
                        name       => 'universalReactions',
                        printOrder => 0,
                        class      => 'UniversalReaction',
                        type       => 'child'
                },
                {
                        name       => 'biomassTemplates',
                        printOrder => 1,
                        class      => 'BiomassTemplate',
                        type       => 'child'
                },
                {
                        name       => 'roles',
                        printOrder => 2,
                        class      => 'Role',
                        type       => 'child'
                },
                {
                        name       => 'rolesets',
                        printOrder => 3,
                        class      => 'RoleSet',
                        type       => 'child'
                },
                {
                        name       => 'complexes',
                        printOrder => 4,
                        class      => 'Complex',
                        type       => 'child'
                },
                {
                        name  => 'aliasSets',
                        class => 'AliasSet',
                        type  => 'child'
                },
        ],
        links       => [
                {
                        name      => 'biochemistry',
                        attribute => 'biochemistry_link',
                        parent    => 'ModelSEED::Store',
                        method    => 'Biochemistry',
                        weak      => 0
                },
        ],
        reference_id_types => [qw(uid alias)],
        version            => 2.0,
};

$objectDefinitions->{UniversalReaction} = {
        parents    => ['Mapping'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'type',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 1
                },
                {
                        name       => 'reaction_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'reaction',
                        attribute => 'reaction_link',
                        parent    => 'Biochemistry',
                        method    => 'reactions'
                },
        ]
};

$objectDefinitions->{BiomassTemplate} = {
        parents    => ['Mapping'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 1
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'class',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'dna',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'rna',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'protein',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'lipid',
                        printOrder => 5,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'cellwall',
                        printOrder => 6,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'cofactor',
                        printOrder => 7,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'energy',
                        printOrder => 8,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                }
        ],
        subobjects => [
                {
                        name  => 'biomassTemplateComponents',
                        class => 'BiomassTemplateComponent',
                        type  => 'child'
                },
        ],
        links       => []
};

$objectDefinitions->{BiomassTemplateComponent} = {
        parents    => ['BiomassTemplate'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 1
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'class',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'compound_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 0,
                },
                {
                        name       => 'coefficientType',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'coefficient',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Num',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'condition',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => '0'
                },
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'compound',
                        attribute => 'compound_link',
                        parent    => 'Biochemistry',
                        method    => 'compounds'
                },
        ]
};

$objectDefinitions->{Role} = {
        alias      => 'Mapping',
        parents    => ['Mapping'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'seedfeature',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 36,
                        req        => 0
                }
        ],
        subobjects         => [],
        links              => [],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{RoleSet} = {
        alias      => 'Mapping',
        parents    => ['Mapping'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 3,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'class',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => 'unclassified'
                },
                {
                        name       => 'subclass',
                        printOrder => 2,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => 'unclassified'
                },
                {
                        name       => 'type',
                        printOrder => 4,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 32,
                        req        => 1
                },
                {
                        name       => 'role_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                }
        ],
        subobjects => [],
        links              => [
                {
                        name      => 'roles',
                        attribute => 'role_links',
                        parent    => 'Mapping',
                        method    => 'roles',
                        array => 1
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{Complex} = {
        alias      => 'Mapping',
        parents    => ['Mapping'],
        class      => 'child',
        attributes => [
                {
                        name       => 'uid',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::uid',
                        req        => 0
                },
                {
                        name       => 'modDate',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'Str',
                        req        => 0
                },
                {
                        name       => 'name',
                        printOrder => 1,
                        perm       => 'rw',
                        type       => 'ModelSEED::varchar',
                        req        => 0,
                        default    => ''
                },
                {
                        name       => 'reaction_links',
                        printOrder => -1,
                        perm       => 'rw',
                        type       => 'ArrayRef[ModelSEED::subobject_link]',
                        req        => 0,
                        default    => 'sub{return [];}'
                },
        ],
        subobjects => [
                {
                        name  => 'complexroles',
                        class => 'ComplexRole',
                        type  => 'encompassed'
                }
        ],
        links              => [
                {
                        name      => 'reactions',
                        attribute => 'reaction_links',
                        parent    => 'Biochemistry',
                        method    => 'reactions',
                        array => 1
                }
        ],
        reference_id_types => [qw(uid)],
};

$objectDefinitions->{ComplexRole} = {
        parents    => ['Complex'],
        class      => 'encompassed',
        attributes => [
                {
                        name       => 'role_link',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'ModelSEED::subobject_link',
                        req        => 1
                },
                {
                        name       => 'optional',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Int',
                        req        => 0,
                        default    => '0'
                },
                {
                        name       => 'type',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Str',
                        len        => 1,
                        req        => 0,
                        default    => 'G'
                },
                {
                        name       => 'triggering',
                        printOrder => 0,
                        perm       => 'rw',
                        type       => 'Int',
                        len        => 1,
                        req        => 0,
                        default    => '1'
                }
        ],
        subobjects  => [],
        links       => [
                {
                        name      => 'role',
                        attribute => 'role_link',
                        parent    => 'Mapping',
                        method    => 'roles'
                }
        ]
};

#ORPHANED OBJECTS THAT STILL NEED TO BE BUILT INTO AN OBJECT TREE
#$objectDefinitions->{Strain} = {
#       parents => ['Genome'],
#       class => 'child',
#       attributes => [
#               {name => 'uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'modDate',printOrder => -1,perm => 'rw',type => 'Str',req => 0},
#               {name => 'name',printOrder => 0,perm => 'rw',type => 'ModelSEED::varchar',req => 0,default => ""},
#               {name => 'source',printOrder => 0,perm => 'rw',type => 'ModelSEED::varchar',req => 1},
#               {name => 'class',printOrder => 0,perm => 'rw',type => 'ModelSEED::varchar',req => 0,default => ""},
#       ],
#       subobjects => [
#               {name => "deletions",class => "Deletion",type => "child"},
#               {name => "insertions",class => "Insertion",type => "child"},
#       ],
#       primarykeys => [ qw(uuid) ],
#       links => [],
#    reference_id_types => [ qw(uuid) ],
#};
#
#$objectDefinitions->{Deletion} = {
#       parents => ['Genome'],
#       class => 'child',
#       attributes => [
#               {name => 'uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'start',printOrder => 0,perm => 'rw',type => 'Int',req => 0},
#               {name => 'stop',printOrder => 0,perm => 'rw',type => 'Int',req => 0,default => ""},
#       ],
#       subobjects => [],
#       primarykeys => [ qw(uuid) ],
#       links => [],
#    reference_id_types => [ qw(uuid) ],
#};
#
#$objectDefinitions->{Insertion} = {
#       parents => ['Genome'],
#       class => 'child',
#       attributes => [
#               {name => 'uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'insertionTarget',printOrder => 0,perm => 'rw',type => 'Int',req => 0},
#               {name => 'sequence',printOrder => 0,perm => 'rw',type => 'Str',req => 0,default => ""},
#       ],
#       subobjects => [],
#       primarykeys => [ qw(uuid) ],
#       links => [],
#    reference_id_types => [ qw(uuid) ],
#};
#
#$objectDefinitions->{Experiment} = {
#       parents => ["ModelSEED::Store"],
#       class => 'indexed',
#       attributes => [
#               {name => 'uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'genome_uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},#I think this should be Strain.Right now, we’re linking an experiment to a single GenomeUUID here, but I think it makes more sense to link to a single StrainUUID, which is what we do in the Price DB.
#               {name => 'name',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#               {name => 'description',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#               {name => 'institution',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#               {name => 'source',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#       ],
#       subobjects => [],
#       primarykeys => [ qw(uuid) ],
#       links => [
#               {name => "genome",attribute => "genome_uuid",parent => "ModelSEED::Store",method=>"genomes"},
#       ],
#    reference_id_types => [ qw(uuid alias) ],
#    version => 1.0,
#};
#
#$objectDefinitions->{ExperimentDataPoint} = {
#       parents => ["Experiment"],
#       class => 'child',
#       attributes => [
#               {name => 'uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'strain_uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},#Not needed if it’s in the experiment table? I think we need to be consistent in defining where in these tables to put e.g. genetic perturbations done in an experiment.
#               {name => 'media_uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'pH',printOrder => 0,perm => 'rw',type => 'Num',req => 0},
#               {name => 'temperature',printOrder => 0,perm => 'rw',type => 'Num',req => 0},
#               {name => 'buffers',printOrder => 0,perm => 'rw',type => 'Str',req => 0},#There could be multiple buffers in a single media. Would this be listed in the Media table? Multiple buffers in single media isn’t something we’ve run across yet and seems like a rarity at best, since their purpose is maintaining pH.  We discussed just listing the buffer here, without amount, because the target pH should dictate the amount of buffer.
#               {name => 'phenotype',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#               {name => 'notes',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#               {name => 'growthMeasurement',printOrder => 0,perm => 'rw',type => 'Num',req => 0},#Would these be better in their own table? IT’s just another type of measurement just like the flux, metabolite, etc... One reason to keep the growth measurements here is unit consistency; moving them to the other table with the other flux measurements would require a clear division between growth rates and secretion/uptake rates to distinguish between 1/h and mmol/gDW/h. Rather than do that, I think keeping them in separate tables makes for an easy, logical division.
#               {name => 'growthMeasurementType',printOrder => 0,perm => 'rw',type => 'Str',req => 0},#Would these be better in their own table?
#       ],
#       subobjects => [
#               {name => "fluxMeasurements",class => "FluxMeasurement",type => "child"},
#               {name => "uptakeMeasurements",class => "UptakeMeasurement",type => "child"},
#               {name => "metaboliteMeasurements",class => "MetaboliteMeasurement",type => "child"},
#               {name => "geneMeasurements",class => "GeneMeasurement",type => "child"},
#       ],
#       primarykeys => [ qw(uuid) ],
#       links => [
#               {name => "strain",attribute => "strain_uuid",parent => "Genome",method=>"strains"},
#               {name => "media",attribute => "media_uuid",parent => "Biochemistry",method=>"media"},
#       ],
#    reference_id_types => [ qw(uuid) ],
#};
#
#$objectDefinitions->{FluxMeasurement} = {
#       parents => ["ExperimentDataPoint"],
#       class => 'encompassed',
#       attributes => [
#               {name => 'value',printOrder => 0,perm => 'rw',type => 'Str',req => 0},#This could get confusing. Make sure the rate is defined relative to the way that the reaction itself is defined (i.e. even if the directionality of the reaction is <= we should define the rate relative to the forward direction, and if it is consistent with the directionality constraint it would be negative)
#               {name => 'reacton_uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'compartment_uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'type',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#       ],
#       subobjects => [],
#       primarykeys => [ qw(uuid) ],
#       links => [
#               {name => "reaction",attribute => "reacton_uuid",parent => "Biochemistry",method=>"reactions"},
#               {name => "compartment",attribute => "compartment_uuid",parent => "Biochemistry",method=>"compartments"},
#       ],
#};
#
#$objectDefinitions->{UptakeMeasurement} = {
#       parents => ["ExperimentDataPoint"],
#       class => 'encompassed',
#       attributes => [
#               {name => 'value',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#               {name => 'compound_uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'type',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#       ],
#       subobjects => [],
#       primarykeys => [ qw(uuid) ],
#       links => [
#               {name => "compound",attribute => "compound_uuid",parent => "Biochemistry",method=>"compounds"},
#       ],
#};
#
#$objectDefinitions->{MetaboliteMeasurement} = {
#       parents => ["ExperimentDataPoint"],
#       class => 'encompassed',
#       attributes => [
#               {name => 'value',printOrder => 0,perm => 'rw',type => 'Str',req => 0},#In metabolomic experiments it is often hard to measure precisely whether a metabolite is present or not. and (even more so) it’s concentration. However, I imagine it is possible to guess a “probability” of particular compounds being present or not. I wanted to talk to one of the guys at Argonne (The guy who was trying to schedule the workshop for KBase) about metabolomics but we ran out of time. We should consult with a metabolomics expert on what a realistic thing to put into this table would be.
#               {name => 'compound_uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'compartment_uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},#I changed this from “extracellular [0/1]” since we could techincally measure them in any given compartment, not just cytosol vs. extracellular
#               {name => 'method',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#       ],
#       subobjects => [],
#       primarykeys => [ qw(uuid) ],
#       links => [
#               {name => "compound",attribute => "compound_uuid",parent => "Biochemistry",method=>"compounds"},
#               {name => "compartment",attribute => "compartment_uuid",parent => "Biochemistry",method=>"compartments"},
#       ],
#};
#
#$objectDefinitions->{GeneMeasurement} = {
#       parents => ["ExperimentDataPoint"],
#       class => 'encompassed',
#       attributes => [
#               {name => 'value',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#               {name => 'feature_uuid',printOrder => 0,perm => 'rw',type => 'ModelSEED::uuid',req => 0},
#               {name => 'method',printOrder => 0,perm => 'rw',type => 'Str',req => 0},
#       ],
#       subobjects => [],
#       primarykeys => [ qw(uuid) ],
#       links => [
#               {name => "feature",attribute => "feature_uuid",parent => "Genome",method=>"features"},
#       ],
#};

sub objectDefinitions {
        return $objectDefinitions;
}

1;
