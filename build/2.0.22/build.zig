const std = @import("std");

pub fn build(b: *std.Build) !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const alloc = gpa.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const with_tls = b.option(bool, "WITH_TLS", "Build mosquitto with TLS") orelse false;
    const version = b.option([]const u8, "version", "mosquitto version string") orelse "0.0.0";

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
    mosquitto.addIncludePath(mosquitto_dep.path("lib"));
    mosquitto.addIncludePath(mosquitto_dep.path("deps"));
    mosquitto.addIncludePath(mosquitto_dep.path("include"));

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
        // lib - shared utility functions needed by broker
        //"lib/actions.c",
        "lib/alias_mosq.c",
        //"lib/callbacks.c",
        //"lib/connect.c",
        //"lib/handle_auth.c",
        //"lib/handle_connack.c",
        //"lib/handle_disconnect.c",
        "lib/handle_ping.c",
        "lib/handle_pubackcomp.c",
        //"lib/handle_publish.c",
        "lib/handle_pubrec.c",
        "lib/handle_pubrel.c",
        "lib/handle_suback.c",
        "lib/handle_unsuback.c",
        //"lib/helpers.c",
        //"lib/logging_mosq.c",
        //"lib/loop.c",
        "lib/memory_mosq.c",
        //"lib/messages_mosq.c",
        "lib/misc_mosq.c",
        //"lib/mosquitto.c",
        "lib/net_mosq_ocsp.c",
        "lib/net_mosq.c",
        //"lib/options.c",
        "lib/packet_datatypes.c",
        "lib/packet_mosq.c",
        "lib/property_mosq.c",
        //"lib/read_handle.c",
        "lib/send_connect.c",
        "lib/send_disconnect.c",
        "lib/send_mosq.c",
        "lib/send_publish.c",
        "lib/send_subscribe.c",
        "lib/send_unsubscribe.c",
        //"lib/socks_mosq.c",
        //"lib/srv_mosq.c",
        "lib/strings_mosq.c",
        //"lib/thread_mosq.c",
        "lib/time_mosq.c",
        "lib/tls_mosq.c",
        "lib/utf8_mosq.c",
        "lib/util_mosq.c",
        "lib/util_topic.c",
        "lib/will_mosq.c",

        // src - broker only
        "src/bridge_topic.c",
        "src/bridge.c",
        "src/conf_includedir.c",
        "src/conf.c",
        "src/context.c",
        "src/control.c",
        "src/database.c",
        "src/handle_auth.c",
        "src/handle_connack.c",
        "src/handle_connect.c",
        "src/handle_disconnect.c",
        "src/handle_publish.c",
        "src/handle_subscribe.c",
        "src/handle_unsubscribe.c",
        "src/keepalive.c",
        "src/logging.c",
        "src/loop.c",
        "src/memory_public.c",
        "src/mosquitto.c",
        "src/mux_epoll.c",
        "src/mux_poll.c",
        "src/mux.c",
        "src/net.c",
        "src/password_mosq.c",
        "src/persist_read_v234.c",
        "src/persist_read_v5.c",
        "src/persist_read.c",
        "src/persist_write_v5.c",
        "src/persist_write.c",
        // "src/plugin_debug.c",
        // "src/plugin_defer.c",
        "src/plugin_public.c",
        "src/plugin.c",
        "src/property_broker.c",
        "src/read_handle.c",
        "src/retain.c",
        "src/security_default.c",
        "src/security.c",
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
