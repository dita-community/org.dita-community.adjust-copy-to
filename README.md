org.dita4publishers.adjust-copy-to
======================

Post processes the resolve map (output of the mappull preprocess step)
in order to add additional copy-to values in order to ensure unique
result files for all references to a given topic or to impose additional
output filenaming rules, such as using navigation keys for result filenames.

This process should be run between the mappull and chunk steps of the normal
OT preprocess sequence.   

Depends on the org.dita-community-common.xslt plugin <https://github.com/dita-community/org.dita-community.common.xslt>

### Testing Notes

The directory test/Chunkattribute is copied from the OT's testsuite repo (https://github.com/dita-ot/testsuite)
