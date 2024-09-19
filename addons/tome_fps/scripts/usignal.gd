class_name USignal

## Calls a signal only once at the end of a frame.
## Useful for inventories and ui.
static func emit_queued(sig: Signal, args := []):
	var obj := sig.get_object()
	var sig_key: String = "%s_dirty" % sig.get_name()
	if not obj.has_meta(sig_key):
		obj.set_meta(sig_key, true)
		sig.emit.bindv(args).call_deferred()
		obj.remove_meta.call_deferred(sig_key)
