require "seqtrimnext/version"

ROOT_PATH=File.join(File.dirname(__FILE__),'seqtrimnext')

$: << File.expand_path(File.join(ROOT_PATH, 'classes'))

#finds the classes that were in the folder 'plugins'
$: << File.expand_path(File.join(ROOT_PATH, 'plugins'))


#finds the classes that were in the folder 'plugins'
$: << File.expand_path(File.join(ROOT_PATH, 'actions'))

#finds the classes that were in the folder 'utils'
$: << File.expand_path(File.join(ROOT_PATH, 'utils'))

$: << File.expand_path(File.join(ROOT_PATH, 'classes','em_classes'))

$: << File.expand_path(File.join(ROOT_PATH, 'latex','classes'))

module Seqtrimnext
  # Your code goes here...
end
