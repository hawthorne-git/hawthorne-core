# v1.1 (CORE)
# required as poster images were created in active storage with the record type: Administration::Web::FabricPrecutType
# long-term plan is to rename all record types to core, then remove this class extension

class Administration::Web::FabricPrecutType < HawthorneCore::ActiveRecordBase
end