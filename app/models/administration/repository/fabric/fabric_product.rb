# v1.1 (CORE)
# required as images with and without ruler, as they were created in active storage with the record type: Administration::Repository::Fabric::FabricProduct
# long-term plan is to rename all record types to core, then remove this class extension

class Administration::Repository::Fabric::FabricProduct < ActiveRecordBase
end