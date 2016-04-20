# CouchbaseLiteSwift

This Swift wrapper for the [Couchbase Lite iOS](https://github.com/couchbase/couchbase-lite-ios) makes working with Couchbase Lite even easier. Have a brief look at the following examples and you'll get a feeling of how easy working with CouchbaseLite becomes.

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