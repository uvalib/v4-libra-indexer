# v4-libra-indexer

This repo contains the code for creating Solr documents for sending to Virgo4 from the new Libra Open repository which is based on DSpace, for the Libra Data repository, and ALSO for the Avalon repository.   It also USED to contain the code for creating Solr Documents for Virgo from Libra ETD, and the older Libra Open repository which was NOT based on DSpace.

The workflow for all of the data sources are largely similar:  For each of the Virgo instances (staging and production) contact the associated data source instance to download ALL of the metadata currently contained in the data source as XML data,  transform that data via a custom XSLT transformation to match the fields wanted by Virgo, and then upload the resulting records to the S3 bucket for incoming Solr documents that then triggers those records being added to either staging or production Virgo Solr.

If for some reason you need to see the older, now-deleted code for Libra ETD or Libra Open, you can access the repo at tag ["archive/pre-remove-libraetd-and-libraoc" ](https://github.com/uvalib/v4-libra-indexer/tree/archive/pre-remove-libraetd-and-libraoc)

There are two different terraform directories for deploying this code:  
* terraform-infrastructure/scheduled_services/v4-libra-indexer
* terraform_infrastructure/scheduled_services/v4-avalon-indexer

And also two separate TeamCity tasks for deploying this code:
* https://teamcity.lib.virginia.edu/project/Virgo4_AvalonIndexerDeploy
* https://teamcity.lib.virginia.edu/project/Virgo4_LibraIndexerDeploy
