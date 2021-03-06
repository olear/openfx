
# Get architecture as defined by the OFX standard
function(get_ofx_architecture OFX_ARCH)
    # Win
    if(MINGW)
        set(OFX_ARCH "Win32" PARENT_SCOPE)
        if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "x86_64")
            set(OFX_ARCH "Win64" PARENT_SCOPE)
        endif()
    # FreeBSD
    elseif(${CMAKE_SYSTEM_NAME} STREQUAL "FreeBSD")
        set(OFX_ARCH "FreeBSD-x86" PARENT_SCOPE)
        if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "x86_64")
            set(OFX_ARCH "FreeBSD-x86-64" PARENT_SCOPE)
        endif()
    # MacOS
    elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Darwin")
        set(OFX_ARCH "MacOS" PARENT_SCOPE)
    # Linux
    else()
        set(OFX_ARCH "Linux-x86" PARENT_SCOPE)
        if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "x86_64")
            set(OFX_ARCH "Linux-x86-64" PARENT_SCOPE)
        endif()
    endif()
endfunction(get_ofx_architecture) 


# Create a new OFX plugin
function(create_ofx_plugin PLUGIN_NAME PLUGIN_SRC PLUGIN_LDFLAGS PLUGIN_RESOURCES PLUGIN_INCLUDES PLUGIN_EXTRA_SOURCES)
    GET_PROPERTY(OPENFX_PROJECT_SOURCE_DIR GLOBAL PROPERTY OPENFX_PROJECT_SOURCE_DIR)
    set(OFX_SUPPORT_HEADER_DIR "${OPENFX_PROJECT_SOURCE_DIR}/Support/include")

    foreach(SOURCE_DIR ${PLUGIN_SRC})
        file(GLOB_RECURSE PLUGIN_GET_SOURCES "${SOURCE_DIR}/*.cpp")
        set(PLUGIN_SOURCES "${PLUGIN_SOURCES};${PLUGIN_GET_SOURCES}")
    endforeach(SOURCE_DIR)

    include_directories(${PLUGIN_INCLUDES})

    # Plugin target is a shared library
    add_library(${PLUGIN_NAME} MODULE ${PLUGIN_SOURCES} ${PLUGIN_EXTRA_SOURCES})

    # Link with OfxSupport library
    target_link_libraries(${PLUGIN_NAME} OfxSupport)
    set_target_properties(${PLUGIN_NAME} PROPERTIES SUFFIX ".ofx")
    set_target_properties(${PLUGIN_NAME} PROPERTIES PREFIX "")

    # Link with openGL libraries
    find_package(OpenGL)
    if(NOT OPENGL_FOUND)
        message(STATUS "Plugin ${PLUGIN_NAME}: OpenGL not found. Please set OPENGL_LIBRARIES.")
    endif()
    target_link_libraries(${PLUGIN_NAME} ${OPENGL_LIBRARIES} ${PLUGIN_LDFLAGS})

    # Add extra flags to the link step of the plugin
    if(APPLE)
        set_target_properties(${PLUGIN_NAME} PROPERTIES LINK_FLAGS "-bundle -fvisibility=hidden -exported_symbols_list,${OFX_SUPPORT_HEADER_DIR}/osxSymbols")
        set_target_properties(${PLUGIN_NAME} PROPERTIES INSTALL_RPATH "@loader_path/../Frameworks;@loader_path/../Libraries")
    elseif(WIN32)
        set_target_properties(${PLUGIN_NAME} PROPERTIES LINK_FLAGS "-fvisibility=hidden,--version-script=${OFX_SUPPORT_HEADER_DIR}/linuxSymbols")
    else()
        set_target_properties(${PLUGIN_NAME} PROPERTIES LINK_FLAGS "-Wl,-fvisibility=hidden,--version-script=${OFX_SUPPORT_HEADER_DIR}/linuxSymbols")
        set_target_properties(${PLUGIN_NAME} PROPERTIES INSTALL_RPATH "$ORIGIN/../../Libraries")
    endif()

    # Install OFX plugin
    get_ofx_architecture(OFX_ARCH)
    install(TARGETS ${PLUGIN_NAME}
            DESTINATION "${CMAKE_INSTALL_PREFIX}/OFX/${PLUGIN_NAME}.ofx.bundle/Contents/${OFX_ARCH}"
            COMPONENT OfxPlugins
            OPTIONAL)
    if (EXISTS "${PROJECT_SOURCE_DIR}/${PLUGIN_SRC}/Info.plist")
        install(FILES "${PROJECT_SOURCE_DIR}/${PLUGIN_SRC}/Info.plist"
                DESTINATION "${CMAKE_INSTALL_PREFIX}/OFX/${PLUGIN_NAME}.ofx.bundle/Contents")
    endif()
    if (PLUGIN_RESOURCES)
        install(FILES ${PLUGIN_RESOURCES}
                DESTINATION "${CMAKE_INSTALL_PREFIX}/OFX/${PLUGIN_NAME}.ofx.bundle/Contents/Resources")
    endif()

endfunction(create_ofx_plugin)
