# !! DEPRECATED !!

This repository is no longer actively maintained.

# CouchbaseLiteSwift

This Swift wrapper for the [Couchbase Lite iOS](https://github.com/couchbase/couchbase-lite-ios) makes working with Couchbase Lite even easier. Have a brief look at the following examples and you'll get a feeling of how easy working with CouchbaseLite becomes.

# Examples

See https://gitlab.com/couchbaseliteswift/examples for a working example.

# Include via Carthage

CouchbaseLiteSwift can be included into any iOS project using [Carthage](https://github.com/carthage/carthage).
Simply add the following line to your Cartfile:

```
git "https://gitlab.com/couchbaseliteswift/framework.git" ~> 0.1
```

Run `carthage update --platform ios`, and you should now have the latest version of CouchbaseLiteSwift and CouchbaseLite iOS in your Carthage folder.

# Building the Framework

## Checking out the Code

1. Use Git to clone the CouchbaseLiteSwift repository to your local disk

```
$: git clone https://gitlab.com/couchbaseliteswift/framework.git CouchbaseLiteSwift
```

2. Move into the `CouchbaseLiteSwift` directory:

```
$: cd CouchbaseLiteSwift
```

3. (Optional) If you want to build a nonstandard branch, enter `git checkout` followed by the branch name:

```
$: git checkout development
```

4. Build the CouchbaseLiteSwift dependencies using Carthage

```
$: carthage update --platform ios
```

## Building

Open CouchbaseLiteSwift.xcworkspace

```
$: open CouchbaseLiteSwift.xcworkspace
```

# API

## CLSModel

### Define

```
import Foundation
import CouchbaseLiteSwift

@objc(Person)
class Person: CLSModel{
@NSManaged var givenName: NSString?
@NSManaged var familyName: NSString?
@NSManaged var age: NSNumber?
}
```

### Create
```
let person = try Person.create([
"givenName": "Bibi",
"familyName": "Blocksberg",
"age": 14
])
```

### Save
```
try person.save()
```

### Create & Save
```
try Person.create([
"givenName": "Bibi",
"familyName": "Blocksberg",
"age": 14
]).save()
```

### Delete
```
try person.deleteDocument()
```

## CLSQuery

### Easy

```
let people = CLSQuery<Person>()
.conditions("givenName != '' AND familyName != ''")
```

### Complex

```
let people = CLSQuery<Person>().conditions([
"givenName != ''",
"AND familyName != ''",
"AND (",
"age < 18",
"OR age > 50",
")"])
.sort("familyName", order: .DESC)
```

### Looping
```
for person in CLSQuery<Person>(){
print(person.givenName, person.familyName)
}
```

### Bulk delete

```
try CLSQuery<Person>()
.conditions("familyName = 'Betschart'")
.deleteDocuments()
```

### Generic query

```
let people = CLSQuery<CLSModel>(type: Person.self)
```

## CLSAttachment

A helper class, which allows you to enrich regular file attachments with meta data.
You are able to receive and set all attachments `[CLSAttachment]?` by using the `CLSModel.attachments` property.

## CLSAttachmentType

## CLSDatabase

## CLSDatabaseConfiguration

## CLSDatabaseSetup

## CLSDatabaseSchemaMigration
