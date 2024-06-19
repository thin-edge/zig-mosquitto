const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mosquitto = b.addExecutable(.{
        .name = "mosquitto",
        .target = target,
        .optimize = optimize,
    });
    mosquitto.addIncludePath(.{ .path = "mosquitto" });
    mosquitto.addIncludePath(.{ .path = "mosquitto/src" });
    mosquitto.addIncludePath(.{ .path = "mosquitto/lib" });
    mosquitto.addIncludePath(.{ .path = "mosquitto/deps" });
    mosquitto.addIncludePath(.{ .path = "mosquitto/include" });
    mosquitto.addCSourceFiles(&.{
        "mosquitto/src/mosquitto.c",
       "mosquitto/lib/alias_mosq.c",
       // "mosquitto/lib/handle_auth.c",       // The broker uses mosquitto/src/handle_auth.c
       // "mosquitto/lib/handle_disconnect.c",
       "mosquitto/lib/handle_pubackcomp.c",
       "mosquitto/lib/handle_pubrec.c",
       "mosquitto/lib/handle_suback.c",
       // "mosquitto/lib/handle_connack.c",
       "mosquitto/lib/handle_ping.c",
       // "mosquitto/lib/handle_publish.c",
       "mosquitto/lib/handle_pubrel.c",
       "mosquitto/lib/handle_unsuback.c",
       "mosquitto/lib/memory_mosq.c",
       "mosquitto/lib/misc_mosq.c",
       "mosquitto/lib/net_mosq.c",
       "mosquitto/lib/net_mosq_ocsp.c",
       "mosquitto/lib/packet_datatypes.c",
       "mosquitto/lib/packet_mosq.c",
       "mosquitto/lib/property_mosq.c",
       // "mosquitto/lib/read_handle.c",  // The broker uses mosquitto/src/read_handle.c
       "mosquitto/lib/send_connect.c",
       "mosquitto/lib/send_disconnect.c",
       "mosquitto/lib/send_mosq.c",
       "mosquitto/lib/send_publish.c",
       "mosquitto/lib/send_subscribe.c",
       "mosquitto/lib/send_unsubscribe.c",
       "mosquitto/lib/strings_mosq.c",
       "mosquitto/lib/time_mosq.c",
       "mosquitto/lib/tls_mosq.c",
       "mosquitto/lib/util_mosq.c",
       "mosquitto/lib/util_topic.c",
       "mosquitto/lib/utf8_mosq.c",
       "mosquitto/lib/will_mosq.c",
       "mosquitto/src/bridge.c",
       "mosquitto/src/bridge_topic.c",
       "mosquitto/src/conf.c",
       "mosquitto/src/conf_includedir.c",
       "mosquitto/src/context.c",
       "mosquitto/src/control.c",
       "mosquitto/src/database.c",
       "mosquitto/src/handle_auth.c",
       "mosquitto/src/handle_connack.c",
       "mosquitto/src/handle_connect.c",
       "mosquitto/src/handle_disconnect.c",
       "mosquitto/src/handle_publish.c",
       "mosquitto/src/handle_subscribe.c",
       "mosquitto/src/handle_unsubscribe.c",
       "mosquitto/src/keepalive.c",
       "mosquitto/src/logging.c",
       "mosquitto/src/loop.c",
       "mosquitto/src/memory_public.c",
       "mosquitto/src/mux.c",
       "mosquitto/src/mux_poll.c",
       "mosquitto/src/net.c",
       "mosquitto/src/password_mosq.c",
       "mosquitto/src/persist_read.c",
       "mosquitto/src/persist_read_v5.c",
       "mosquitto/src/persist_read_v234.c",
       "mosquitto/src/persist_write.c",
       "mosquitto/src/persist_write_v5.c",
       "mosquitto/src/plugin.c",
       "mosquitto/src/plugin_public.c",
       "mosquitto/src/property_broker.c",
       "mosquitto/src/read_handle.c",
       "mosquitto/src/retain.c",
       "mosquitto/src/security.c",
       "mosquitto/src/security_default.c",
       "mosquitto/src/send_auth.c",
       "mosquitto/src/send_connack.c",
       "mosquitto/src/send_suback.c",
       "mosquitto/src/send_unsuback.c",
       "mosquitto/src/session_expiry.c",
       "mosquitto/src/signals.c",
       "mosquitto/src/subs.c",
       "mosquitto/src/topic_tok.c",
       "mosquitto/src/will_delay.c",
    }, &.{
        "-DWITH_BROKER",
        "-DWITH_PERSISTENCE",
        "-DVERSION=\"2.0.18\"",
        "-Wall",
        "-W",
    });
    mosquitto.linkLibC();

    b.installArtifact(mosquitto);
}
