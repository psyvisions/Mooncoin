use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Catalyst::Model::Namecoin',
    VERSION_FROM      => 'lib/Catalyst/Model/Namecoin.pm', # finds $VERSION
    PREREQ_PM         => {
      'Moose' => 1.08,
      'Finance::Namecoin' => 0.001,
      'Catalyst' => 5.8,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Model/Namecoin.pm', # retrieve abstract from module
       AUTHOR         => 'Pavel Karoukin <pavel@yepcorp.com>') : ()),
);
