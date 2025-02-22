# - Find BigWorld-bundled OpenSSL installation
# Try to find the OpenSSL libraries bundled with BigWorld
# Once done, this will define
#	BWOPENSSL_FOUND - BigWorld-bundled OpenSSL is present and compiled
#	BWOPENSSL_INCLUDE_DIRS - The BigWorld-bundled OpenSSL include directories
#	BWOPENSSL_LIBRARIES - The libraries needed to use the BigWorld-bundled OpenSSL

# Based on FindScaleformSDK.cmake, which is
# based on http://www.cmake.org/Wiki/CMake:How_To_Find_Libraries
# and FindALSA.cmake, which is apparently current best-practice

# Hide all of the OpenSSL build madness.
IF( MSVC )
	# Note: Remote server build windows builds
	# due to .a files not existing at this point in time.
	IF( BW_COMPILER_TOKEN STREQUAL "vc10" )
		SET( BWOPENSSL_DIR_TAIL "-vs2010" )
	ELSEIF( BW_COMPILER_TOKEN STREQUAL "vc11" )
		SET( BWOPENSSL_DIR_TAIL "-vs2012" )
	ELSEIF( BW_COMPILER_TOKEN STREQUAL "vc12" )
		SET( BWOPENSSL_DIR_TAIL "-vs2013" )
	ELSEIF( BW_COMPILER_TOKEN STREQUAL "vc14" )
		SET( BWOPENSSL_DIR_TAIL "-vs2015" )
	ELSE()
		MESSAGE( FATAL_ERROR
			"No Win32 OpenSSL present for ${BW_COMPILER_TOKEN}" )
	ENDIF()

	IF( BW_IS_UWP )
		SET( BWOPENSSL_DIR_TAIL "${BWOPENSSL_DIR_TAIL}-uwp" )			
	ENDIF()

	IF( BW_ARCH_32 )
		SET( BWOPENSSL_INC_DIR_NAME include )
		SET( BWOPENSSL_LIB_DIR_NAME lib )
	ELSE()
		SET( BWOPENSSL_INC_DIR_NAME include64 )
		SET( BWOPENSSL_LIB_DIR_NAME lib64 )
	ENDIF()
	# The 64-bit libraries are *32.lib as well.
	# We always use the static release libraries, even in debug mode
	SET( BWOPENSSL_CRYPTO_LIB_NAME libeay32MT )
	SET( BWOPENSSL_SSL_LIB_NAME ssleay32MT )
	SET( BWOPENSSL_LIB_DEBUG_TAIL "d" )

	# OpenSSL is bundled on Windows
	SET( BW_NO_DEFAULT_PATH NO_DEFAULT_PATH )
ELSE()
	SET( BWOPENSSL_DIR_TAIL )
	SET( BWOPENSSL_INC_DIR_NAME include )
	SET( BWOPENSSL_LIB_DIR_NAME )
	SET( BWOPENSSL_CRYPTO_LIB_NAME libcrypto )
	SET( BWOPENSSL_SSL_LIB_NAME libssl )
	SET( BWOPENSSL_LIB_DEBUG_TAIL )
ENDIF()

FIND_PATH( BWOPENSSL_ROOT_DIR 
	${BWOPENSSL_INC_DIR_NAME}/openssl/opensslconf.h
	PATHS ${BW_SOURCE_DIR}/third_party/openssl${BWOPENSSL_DIR_TAIL}
	${BW_NO_DEFAULT_PATH}
)

# BWOpenSSL Include dir
FIND_PATH( BWOPENSSL_INCLUDE_DIR
	openssl/opensslv.h "${BWOPENSSL_ROOT_DIR}/${BWOPENSSL_INC_DIR_NAME}"
	PATHS ${BWOPENSSL_ROOT_DIR}/${BWOPENSSL_INC_DIR_NAME}
	${BW_NO_DEFAULT_PATH}
)

# Extract the version from OPENSSL_VERSION_TEXT in openssl/opensslv.h
IF( BWOPENSSL_INCLUDE_DIR AND EXISTS "${BWOPENSSL_INCLUDE_DIR}/openssl/opensslv.h" )
	FILE( STRINGS "${BWOPENSSL_INCLUDE_DIR}/openssl/opensslv.h"
		_BWOPENSSL_VERSION_STR
		REGEX "^#[\t ]*define[\t ]+OPENSSL_VERSION_TEXT[\t ]+\"OpenSSL [0-9.a-z]+ .*\""
	)
	STRING( REGEX REPLACE "^.*OpenSSL ([^\ ]*) .*$" "\\1"
		BWOPENSSL_VERSION_STRING ${_BWOPENSSL_VERSION_STR}
	)
	UNSET( _BWOPENSSL_VERSION_STR )
ENDIF()

# BWOpenSSL library paths
FIND_LIBRARY( BWOPENSSL_LIBRARY_CRYPTO
	${BWOPENSSL_CRYPTO_LIB_NAME}
	PATHS ${BWOPENSSL_ROOT_DIR}/${BWOPENSSL_LIB_DIR_NAME}
	${BW_NO_DEFAULT_PATH}
)
FIND_LIBRARY( BWOPENSSL_LIBRARY_CRYPTO_DEBUG
	${BWOPENSSL_CRYPTO_LIB_NAME}${BWOPENSSL_LIB_DEBUG_TAIL}
	PATHS ${BWOPENSSL_ROOT_DIR}/${BWOPENSSL_LIB_DIR_NAME}
	${BW_NO_DEFAULT_PATH}
)

FIND_LIBRARY( BWOPENSSL_LIBRARY_SSL
	${BWOPENSSL_SSL_LIB_NAME}
	PATHS ${BWOPENSSL_ROOT_DIR}/${BWOPENSSL_LIB_DIR_NAME}
	${BW_NO_DEFAULT_PATH}
)
FIND_LIBRARY( BWOPENSSL_LIBRARY_SSL_DEBUG
	${BWOPENSSL_SSL_LIB_NAME}${BWOPENSSL_LIB_DEBUG_TAIL}
	PATHS ${BWOPENSSL_ROOT_DIR}/${BWOPENSSL_LIB_DIR_NAME}
	${BW_NO_DEFAULT_PATH}
)

INCLUDE( FindPackageHandleStandardArgs )

#FIND_PACKAGE_HANDLE_STANDARD_ARGS( BWOpenSSL
#	REQUIRED_VARS
#		# Top of BWOpenSSL tree
#		BWOPENSSL_ROOT_DIR
#		# Headers
#		BWOPENSSL_INCLUDE_DIR
#		# Libraries
#		BWOPENSSL_LIBRARY_CRYPTO
#		BWOPENSSL_LIBRARY_CRYPTO_DEBUG
#		BWOPENSSL_LIBRARY_SSL
#		BWOPENSSL_LIBRARY_SSL_DEBUG
#	VERSION_VAR BWOPENSSL_VERSION_STRING
#)

IF( BWOPENSSL_FOUND )
	SET( BWOPENSSL_INCLUDE_DIRS
		${BWOPENSSL_INCLUDE_DIR}
	)

	SET( BWOPENSSL_LIBRARIES
		debug ${BWOPENSSL_LIBRARY_CRYPTO_DEBUG}
		optimized ${BWOPENSSL_LIBRARY_CRYPTO}
		debug ${BWOPENSSL_LIBRARY_SSL_DEBUG}
		optimized ${BWOPENSSL_LIBRARY_SSL}
	)

ENDIF()

MARK_AS_ADVANCED( 
	BWOPENSSL_INCLUDE_DIR
	BWOPENSSL_LIBRARY_CRYPTO
	BWOPENSSL_LIBRARY_SSL
)
