load("//tools/rule_mobile:common.bzl", "join")
load("//tools/rule_mobile:gobind_library.bzl", "gobind_library", "gen_files")
load("@io_bazel_rules_go//go:def.bzl", "go_path")


def _match_file_cmd(java_name, match_file):
    """Command to match file, and write to match_file at the same folder."""
    return """# echo "To match {match_file}"
    for item in $(locations {java_name}); do
        if [[ $$(basename "$${{item}}") == {match_file} ]];
        then
            # echo "Matched file $${{item}}, write to: {match_file}"
            cat "$${{item}}" > $@
        fi
    done
    """.format(java_name=java_name, match_file=match_file)


def gobind(name, deps, java_package = "", objc_prefix = "", tags = [], **kwargs):
    """Creates gobind rules for java and objc."""
    gopath_name = join(name, "gopath")

    # Rule: Generate go_path rule, which sets up environment for the rest.
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
        tags = tags + ["go_path"],
    )

    ## Rules for Java.
    # Rule: Generate java's gobind, which creates two files: "<name>.aar", and "<name>-sources.jar".
    java_name = join(name, "java")
    java_gen_args = ["-javapkg=%s" % java_package] if java_package else []
    unused_java_copts = ["-D__GOBIND_ANDROID__"]
    gobind_library(
        name = java_name,
        original_name = name,
        go_path = gopath_name,
        lang = "java",
        gen_args = java_gen_args,
        tags = tags + ["java"],
        deps = deps,
    )
 
    # Output files of genrule.
    gen = gen_files(java_name, name)
    # Rule: Redirect "<name>.aar" to this folder.
    java_aar_gen_name = join(name, "java", "aar")
    native.genrule(
        name = java_aar_gen_name,
        outs = [gen.short_android_aar],
        cmd = _match_file_cmd(java_name, gen.short_android_aar),
        tools = [java_name],  # Built with host configuration.
    )

    # Redirect "<name>-sources.jar" to this folder.
    native.genrule(
        name = join(name, "java", "jar"),
        outs = [gen.short_android_sources_jar],
        cmd = _match_file_cmd(java_name, gen.short_android_sources_jar),
        tools = [java_name],  # Built with host configuration.
    )

    # Generate aar_import for android.
    native.aar_import(
        name = name + "_aar_import",
        aar = gen.short_android_aar,
        data = [
            java_aar_gen_name,
        ],
    )

    ## Rules for ObjC.
    # Rule: Generates objc xcframework: "<name>.xcframework".
    objc_name = join(name, "objc")
    objc_gen_args = ["-prefix=%s" % objc_prefix] if objc_prefix else []
    unused_objc_copts = [
        "-xobjective-c",
        "-fmodules",
        "-fobjc-arc",
        "-D__GOBIND_DARWIN__",
    ]
    gobind_library(
        name = objc_name,
        original_name = name,
        go_path = gopath_name,
        lang = "objc",
        gen_args = objc_gen_args,
        tags = tags + ["objc"],
        deps = deps,
    )

    # Rule: Redirect "<name>.xcframework" to this folder.
    xcframework_folder = name + ".xcframework"
    native.genrule(
        name = join(name, "objc", "xcframework"),
        outs = [xcframework_folder],
        cmd = "cp -R $(location {objc_name}) $@".format(objc_name=objc_name),
        tools = [objc_name],  # Built with host configuration.
    )
