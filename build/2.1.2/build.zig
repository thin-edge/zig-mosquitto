const std = @import("std");
const zon = @import("build.zig.zon");

pub fn build(b: *std.Build) !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const alloc = gpa.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // NOTE: Force with_tls as building without tls currently fails due to missing ifdef in the mosquitto source code
    const with_tls = b.option(bool, "WITH_TLS", "Build mosquitto with TLS") orelse true;
    const version = b.option([]const u8, "version", "mosquitto version string") orelse zon.version;

    const mosquitto = b.addExecutable(.{
        .name = "mosquitto",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    const mosquitto_dep = b.dependency("mosquitto_src", .{});
    mosquitto.addIncludePath(mosquitto_dep.path(""));
    mosquitto.addIncludePath(mosquitto_dep.path("src"));
    mosquitto.addIncludePath(mosquitto_dep.path("common"));
    mosquitto.addIncludePath(mosquitto_dep.path("lib"));
    mosquitto.addIncludePath(mosquitto_dep.path("libcommon"));
    mosquitto.addIncludePath(mosquitto_dep.path("deps"));
    mosquitto.addIncludePath(mosquitto_dep.path("include"));

    const cjson_dep = b.dependency("cjson", .{});
    const mkdir_cjson = b.addSystemCommand(&[_][]const u8{ "mkdir", "-p", "cjson" });
    const copy_cjson = b.addSystemCommand(&[_][]const u8{"cp"});
    copy_cjson.addFileArg(cjson_dep.path("cJSON.h"));
    copy_cjson.addArg("cjson/cJSON.h");
    copy_cjson.step.dependOn(&mkdir_cjson.step);
    mosquitto.step.dependOn(&copy_cjson.step);
    mosquitto.addIncludePath(b.path("."));
    mosquitto.addCSourceFile(.{ .file = cjson_dep.path("cJSON.c"), .flags = &.{} });

    const sqlite_dep = b.dependency("sqlite", .{});
    mosquitto.addIncludePath(sqlite_dep.path("."));
    mosquitto.addCSourceFile(.{ .file = sqlite_dep.path("sqlite3.c"), .flags = &.{} });

    const microhttpd = b.dependency("microhttpd", .{});
    mosquitto.addIncludePath(microhttpd.path("src/include"));

    // Enable openssl
    if (with_tls) {
        const openssl = b.dependency("openssl", .{ .target = target, .optimize = optimize });
        const libssl = openssl.artifact("ssl");
        const libcrypto = openssl.artifact("crypto");
        _ = for (libcrypto.root_module.include_dirs.items) |include_dir| {
            try mosquitto.root_module.include_dirs.append(b.allocator, include_dir);
        };
        mosquitto.root_module.linkLibrary(libssl);
        mosquitto.root_module.linkLibrary(libcrypto);
    }

    // note: Ideally the source code files should be sorted and the unused files should
    // be commented out rather than deleted from the list to make it easier to see what
    // is and isn't used
    const mosquitto_sources = [_][]const u8{
        "common/json_help.c",

        "libcommon/base64_common.c",
        "libcommon/cjson_common.c",
        "libcommon/file_common.c",
        "libcommon/memory_common.c",
        "libcommon/mqtt_common.c",
        "libcommon/password_common.c",
        "libcommon/property_common.c",
        "libcommon/random_common.c",
        "libcommon/strings_common.c",
        "libcommon/time_common.c",
        "libcommon/topic_common.c",
        "libcommon/utf8_common.c",

        "lib/alias_mosq.c",
        "lib/handle_ping.c",
        "lib/handle_pubackcomp.c",
        "lib/handle_pubrec.c",
        "lib/handle_pubrel.c",
        "lib/handle_suback.c",
        "lib/handle_unsuback.c",
        "lib/net_mosq_ocsp.c",
        "lib/net_mosq.c",
        "lib/net_ws.c",
        "lib/packet_datatypes.c",
        "lib/packet_mosq.c",
        "lib/property_mosq.c",
        "lib/send_mosq.c",
        "lib/send_connect.c",
        "lib/send_disconnect.c",
        "lib/send_publish.c",
        "lib/send_subscribe.c",
        "lib/send_unsubscribe.c",
        "lib/tls_mosq.c",
        "lib/util_mosq.c",
        "lib/will_mosq.c",

        "plugins/acl-file/acl_check.c",
        "plugins/acl-file/acl_parse.c",
        "plugins/password-file/password_check.c",
        "plugins/password-file/password_parse.c",

        "src/acl_file.c",
        "src/bridge.c",
        "src/bridge_topic.c",
        "src/broker_control.c",
        "src/conf.c",
        "src/conf_includedir.c",
        "src/context.c",
        "src/control.c",
        "src/control_common.c",
        "src/database.c",
        "src/handle_auth.c",
        "src/handle_connack.c",
        "src/handle_connect.c",
        "src/handle_disconnect.c",
        "src/handle_publish.c",
        "src/handle_subscribe.c",
        "src/handle_unsubscribe.c",
        "src/http_api.c",
        "src/http_serv.c",
        "src/keepalive.c",
        "src/listeners.c",
        "src/logging.c",
        "src/loop.c",
        "src/mosquitto.c",
        "src/mux.c",
        "src/mux_epoll.c",
        "src/mux_kqueue.c",
        "src/mux_poll.c",
        "src/net.c",
        "src/password_file.c",
        "src/persist_read.c",
        "src/persist_read_v234.c",
        "src/persist_read_v5.c",
        "src/persist_write.c",
        "src/persist_write_v5.c",
        "src/plugin_acl_check.c",
        "src/plugin_basic_auth.c",
        "src/plugin_callbacks.c",
        "src/plugin_cleanup.c",
        "src/plugin_client_offline.c",
        "src/plugin_connect.c",
        "src/plugin_disconnect.c",
        "src/plugin_extended_auth.c",
        "src/plugin_init.c",
        "src/plugin_message.c",
        "src/plugin_persist.c",
        "src/plugin_psk_key.c",
        "src/plugin_public.c",
        "src/plugin_reload.c",
        "src/plugin_subscribe.c",
        "src/plugin_tick.c",
        "src/plugin_unsubscribe.c",
        "src/plugin_v2.c",
        "src/plugin_v3.c",
        "src/plugin_v4.c",
        "src/plugin_v5.c",
        "src/property_broker.c",
        "src/proxy_v1.c",
        "src/proxy_v2.c",
        "src/psk_file.c",
        "src/read_handle.c",
        "src/retain.c",
        "src/security_default.c",
        "src/send_auth.c",
        "src/send_connack.c",
        "src/send_suback.c",
        "src/send_unsuback.c",
        "src/service.c",
        "src/session_expiry.c",
        "src/signals.c",
        "src/subs.c",
        "src/sys_tree.c",
        "src/topic_tok.c",
        "src/watchdog.c",
        "src/websockets.c",
        "src/will_delay.c",
        "src/xtreport.c",
    };

    // construct build arguments
    var mosquitto_flags = std.array_list.Managed([]const u8).init(alloc);
    defer mosquitto_flags.deinit();

    // optional flags
    if (with_tls) {
        try mosquitto_flags.append("-DWITH_TLS");
    }

    // common flags
    try mosquitto_flags.append("-DWITH_BRIDGE");
    try mosquitto_flags.append("-DWITH_BROKER");
    try mosquitto_flags.append("-DWITH_PERSISTENCE");
    // try mosquitto_flags.append("-DWITH_SQLITE");
    // try mosquitto_flags.append("-DWITH_HTTP_API");

    // version
    const version_flag = try std.fmt.allocPrint(alloc, "-DVERSION=\"{s}\"", .{version});
    defer alloc.free(version_flag);
    try mosquitto_flags.append(version_flag);

    try mosquitto_flags.append("-Wall");
    try mosquitto_flags.append("-W");

    for (mosquitto_sources) |src| {
        mosquitto.addCSourceFile(.{ .file = mosquitto_dep.path(src), .flags = mosquitto_flags.items });
    }
    mosquitto.linkLibC();

    b.installArtifact(mosquitto);
}