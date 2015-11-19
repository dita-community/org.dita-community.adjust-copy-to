org.dita-community.adjust-copy-to
=================================

Post processes the resolved map (output of the mappull preprocess step)
in order to add additional copy-to values in order to ensure unique
result files for all references to a given topic or to impose additional
output filenaming rules, such as using navigation keys for result filenames.

The copy-to adjustment is turned on by default. Turn it off using the args.dc-adjust-copy-to.skip 
Ant parameter.

This process should be run between the mappull and chunk steps of the normal
OT preprocess sequence.   

Depends on the org.dita-community-common.xslt plugin <https://github.com/dita-community/org.dita-community.common.xslt>

NOTE: The current implementation does not check the resulting @copy-to values as carefully as it could,
so it's possible to generate inappropriate values, especially if use-nav-keys is on and not all
navigation topicrefs have @keys values. Providing more complete consistency checking of the final
copy-to values is planned for the future.



## Ant Properties

* args.dc-adjust-copy-to.skip - Set to any value (e.g., "true") to turn off copy-to adjustment.
* dc.adjust-copy-to.use-nav-keys - Set to "true" or "on" or "yes" to turn on use of @keys values 
for @copy-to. When turned on, the first (or only) key name in @keys on navigation (normal-role) topicrefs
will be used as the base value
for the @copy-to attribute. For example, if the @keys value "chapter-01", the resulting @copy-to
value will be "chapter-01.dita". This is off by default (do not use navigation keys)
* dc.adjust-copy-to.override-existing-copy-to - Replace existing @copy-to values with values generated
by the adjust-copy-to process, in particular, when use-nav-keys is in effect. This is off (do not
override existing copy-to values) by default.

### Testing Notes

The directory test/Chunkattribute is copied from the OT's testsuite repo (https://github.com/dita-ot/testsuite)
