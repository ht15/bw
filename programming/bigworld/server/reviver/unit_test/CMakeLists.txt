CMAKE_MINIMUM_REQUIRED( VERSION 3.5 )
PROJECT( reviver_unit_test )

INCLUDE( BWStandardProject )

SET( ALL_SRCS
	main.cpp
)

BW_BLOB_SOURCES( BLOB_SRCS ${ALL_SRCS} )

BW_ADD_EXECUTABLE( reviver_unit_test ${BLOB_SRCS} )
BW_TARGET_LINK_LIBRARIES( reviver_unit_test
	cstdmf
	)

BW_ADD_TEST( reviver_unit_test )

BW_PROJECT_CATEGORY( reviver_unit_test "Unit Tests" )
