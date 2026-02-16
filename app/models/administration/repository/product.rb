# v1.1 (CORE)
# required as product images were created in active storage with the record type: Administration::Repository::Product
# long-term plan is to rename all record types to core, then remove this class extension

class Administration::Repository::Product < ActiveRecordBase
end