mr.q
====

JSON AST to RethinkDB query

[![Build Status](https://travis-ci.org/hden/mr.q.svg?branch=master)](https://travis-ci.org/hden/mr.q)

Usage
-----

* expose flexible query as API
* store & exchange query as data

Installation
------------

```sh
npm install --save mr.q
```

Expressions
-----------

* **date** {$date: 'YYYY-MM-DD HH:MM:SS'}
* **between** {$between: [START, END]}
* **in** {$in: [foo, bar]}
* **not in** {$nin: [foo, bar]}
* **contains** {$contains: value}
* **greater than** {$gt: value}
* **greater or equals to** {$ge: value}
* **less than** {$lt: value}
* **less or equal to** {$le: value}

Example
-------

```JavaScript
// Sample data

r.table('mr').insert([
  {
    id: 1,
    type: 'foo',
    name: 'foo1',
    value: 1,
    list: [],
    dt: new Date('2014-08-17 12:00:00')
  }, {
    id: 2,
    type: 'foo',
    name: 'foo2',
    value: 2,
    list: ['A'],
    dt: new Date('2014-08-17 13:00:00')
  }, {
    id: 3,
    type: 'foo',
    name: 'foo3',
    value: 3,
    list: ['A', 'B'],
    dt: new Date('2014-08-17 14:00:00')
  }, {
    id: 4,
    type: 'bar',
    name: 'bar1',
    value: 1,
    list: ['A', 'C'],
    dt: new Date('2014-08-17 12:00:00')
  }, {
    id: 5,
    type: 'bar',
    name: 'bar2',
    value: 2,
    list: ['B', 'C'],
    dt: new Date('2014-08-17 13:00:00')
  }
]);

```

```JavaScript
var r  = require('rethinkdb');
var mr = require('mr.q');
var co = require('co');


co(function*() {
  // documents that have type of 'foo' and name in ['foo1', 'bar1']
  var query = mr.match({
    type: 'foo',
    name: {
      $in: ['foo1', 'bar1']
    }
  });

  var result = yield run(query(table));

  // {
  //   id: 1,
  //   type: 'foo',
  //   name: 'foo1',
  //   value: 1,
  //   list: [],
  //   dt: new Date('2014-08-17 12:00:00')
  // }
})();

co(function*() {
  // Distinct types of documents that have type in ['foo', 'bar']
  // and dt between '2014-08-17 12:00:00' and '2014-08-17 13:30:00'

  var q1 = mr.match({
    type: {
      $in: ['foo', 'bar']
    },
    dt: {
      $between: [
        {
          $date: '2014-08-17 12:00:00'
        }, {
          $date: '2014-08-17 13:30:00'
        }
      ]
    }
  });
  var q2 = mr.aggregate({
    $distinct: 'type'
  });
  var result = yield run(q2(q1(table)));

  // [
  //   {type: 'foo'},
  //   {type: 'bar'}
  // ]
})();
```

more examples can be found in the [test suite](https://github.com/hden/mr.q/blob/master/test/index.coffee)
