load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library", "go_path", "GoLibrary", "GoSource", "GoPath", "go_context")

def _extract_impl(ctx):
    """_extract_impl"""
    go = go_context(ctx)
    outs = []
    tagfile = ctx.actions.declare_file(".tag")

    gomobile_os = ctx.var["gomobile_os"]
    gomobile_cpu = ctx.var["gomobile_cpu"]
    gomobile_extract_dir = ctx.var["gomobile_extract_dir"]

    original_name = ctx.attr.original_name

    outs.append(tagfile)
    ctx.actions.run_shell(
        inputs = [ctx.file.gomobile_main_binary],
        outputs = [tagfile],
        command = """
            cp -f $2 $3 && touch $1
        """,
        arguments = [
            tagfile.path,
            ctx.file.gomobile_main_binary.path,
            "{0}/{1}.{2}_{3}.{4}".format(
                gomobile_extract_dir,
                ctx.attr.original_name, gomobile_os, gomobile_cpu,
                ctx.file.gomobile_main_binary.extension),
        ],
        execution_requirements = {
            "no-sandbox": "1",
            "no-cache": "1",
        },
    )

    if len(ctx.attr.objc_hdrs.files) > 0:
        tagfile_objc_hdrs = ctx.actions.declare_file("%s.objc_hdrs.extract" % original_name)
        outs.append(tagfile_objc_hdrs)
        ctx.actions.run_shell(
            inputs = ctx.attr.objc_hdrs.files,
            outputs = [tagfile_objc_hdrs],
            mnemonic = "GoMobileExtract",
            command = """
                mkdir -p $2 &&
                cp -f ${@:3} $2 &&
                touch $1
            """,
            arguments = [
                tagfile_objc_hdrs.path,
                "{0}/objc_hdrs".format(
                    gomobile_extract_dir)] + [file.path for file in ctx.attr.objc_hdrs.files],
            execution_requirements = {
                "no-sandbox": "1",
                "no-cache": "1",
            },
        )

    if len(ctx.attr.java.files) > 0:
        tagfile_java = ctx.actions.declare_file("%s.java.extract" % original_name)
        outs.append(tagfile_java)
        ctx.actions.run_shell(
            inputs = ctx.attr.java.files,
            outputs = [tagfile_java],
            mnemonic = "GoMobileExtract",
            command = """
                mkdir -p $2 &&
                cp -f ${@:3} $2 &&
                touch $1
            """,
            arguments = [
                tagfile_java.path,
                "{0}/java".format(
                    gomobile_extract_dir)] + [file.path for file in ctx.attr.java.files],
            execution_requirements = {
                "no-sandbox": "1",
                "no-cache": "1",
            },
        )


    return [
        DefaultInfo(
            files = depset(outs),
        ),
    ]

extract = rule(
    _extract_impl,
    attrs = {
        "original_name": attr.string(),
        "gomobile_main_binary": attr.label(allow_single_file=True),
        "objc_hdrs": attr.label(),
        "java": attr.label(),
        "_go_context_data": attr.label(default = Label("@io_bazel_rules_go//:go_context_data")),
    },
    output_to_genfiles = True,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)
