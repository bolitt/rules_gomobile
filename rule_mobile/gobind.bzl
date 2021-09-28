load("//rule_mobile:gobind_library.bzl", "gobind_library")
load("@io_bazel_rules_go//go:def.bzl", "go_path")

def gobind(name, deps, java_package = "", objc_prefix = "", objc_platform_type = "ios", objc_minimum_os_version = "", tags = [], **kwargs):
    """Creates gobind rules for java and objc."""
    gopath_name = name + "@gopath"

    # Generate go_path rule, which sets up environment for the rest.
    go_path(
        name = gopath_name,
        mode = "link",
        include_pkg = True,
        include_transitive = True,
        deps = deps + [
            # For command line.
            "@org_golang_x_mobile//cmd/gomobile:gomobile",
            "@org_golang_x_mobile//cmd/gobind:gobind",
            # For bind.
            "@org_golang_x_mobile//bind:go_default_library",
            "@org_golang_x_mobile//bind/java:go_default_library",
            "@org_golang_x_mobile//bind/seq:go_default_library",
            "@org_golang_x_mobile//bind/objc:go_default_library",
        ],
    )

    ## Rules for Java.
    # Generate java's gobind, which creates two files: "<name>.aar", and "<name>-sources.jar".
    java_name = name + "@java" 
    gobind_library(
        name = java_name,
        original_name = name,
        go_path = gopath_name,
        lang = ["go", "java"],
        java_package = java_package,
        copts = ["-D__GOBIND_ANDROID__"],
        go_tags = tags + ["java"],
        deps = deps,
    )
 
    # Output files of genrule.
    aar_file = name + ".aar"
    jar_file = name + "-sources.jar"
    match_file_cmd = """
    echo "To match {match_file}"
    for item in $(locations {java_name}); do
        if [[ $$(basename "$${{item}}") == {match_file} ]];
        then
            echo "Matched file $${{item}}, write to: {match_file}"
            cat "$${{item}}" > $@
        fi
    done
    """
    # Redirect "<name>.aar" to this folder.
    java_aar_gen_name = name + "@java@aar"
    native.genrule(
        name = java_aar_gen_name,
        outs = [aar_file],
        cmd = match_file_cmd.format(
            java_name=java_name, match_file=aar_file),
        tools = [java_name],  # Built with host configuration.
    )

    # Redirect "<name>-sources.jar" to this folder.
    native.genrule(
        name = name + "@java@jar",
        outs = [jar_file],
        cmd = match_file_cmd.format(
            java_name=java_name, match_file=jar_file),
        tools = [java_name],  # Built with host configuration.
    )

    # Generate aar_import for android.
    native.aar_import(
        name = name + "_aar_import",
        aar = aar_file,
        data = [
            java_aar_gen_name,
        ],
    )

    ## Rules for ObjC.
    # Generates objc xcframework: "<name>.xcframework".
    objc_name = name + "@objc"
    gobind_library(
        name = objc_name,
        original_name = name,
        go_path = gopath_name,
        lang = ["go", "objc"],
        objc_prefix = objc_prefix,
        copts = [
            "-xobjective-c",
            "-fmodules",
            "-fobjc-arc",
            "-D__GOBIND_DARWIN__",
        ],
        go_tags = tags + ["ios"],
        deps = deps,
    )

    # Redirect "<name>.xcframework" to this folder.
    xcframework_folder = name + ".xcframework"
    native.genrule(
        name = name + "@objc@xcframework",
        outs = [xcframework_folder],
        cmd = "cp -R $(location {objc_name}) $@".format(objc_name=objc_name),
        tools = [objc_name],  # Built with host configuration.
    )
