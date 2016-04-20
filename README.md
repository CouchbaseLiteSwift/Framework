# CouchbaseLiteSwift

This Swift wrapper for the [Couchbase Lite iOS](https://github.com/couchbase/couchbase-lite-ios) makes working with Couchbase Lite even easier. Have a brief look at the following examples and you'll get a feeling of how easy working with CouchbaseLite becomes.

# Examples

See https://gitlab.com/couchbaseliteswift/examples for a working example.

# Building the Framework

## Checking out the Code

1. Use Git to clone the CouchbaseLiteSwift repository to your local disk

```
$: git clone https://gitlab.com/couchbaseliteswift/framework.git CouchbaseLiteSwift
```

2. Move into the frameworks directory:

```
$: cd CouchbaseLiteSwift
```

3. (Optional) If you want to build a nonstandard branch, enter `git checkout` followed by the branch name:

```
$: git checkout development
```

4. Checkout the CouchbaseLiteSwift dependencies

```
$: git submodule update --recursive
```

## Building

Open CouchbaseLiteSwift.xcworkspace

```
$: open CouchbaseLiteSwift.xcworkspace
```

The next step depends on whether you want an **optimized** or a **debug** build:

### Optimized Build
Choose "Archive" from the "Product" menu.
Open the Organizer window's Archives tab to find the archive.
Right-click the archive and choose "Show In Finder".
Right-click the archive icon in the Finder and choose "Show Package Contents".
The framework will be inside the "Products" subfolder.

### Debug Build
Choose "Build" from the "Product" menu.
Finding the framework can be tricky as it's buried deep in the build directory, whose location varies depending on your Xcode preferences. Look at the build log in the log navigator pane and the last line of output should include its path.

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
