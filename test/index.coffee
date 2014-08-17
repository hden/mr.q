'use strict'

pool     = require('rethinkdb-pool')({})
_        = require 'underscore'
r        = require 'rethinkdb'
{expect} = require 'chai'
co       = require 'co'

fixture  = require "#{__dirname}/fixture"
mr       = require "#{__dirname}/../"

###
Please run `$ rethinkdb` to start a rethinkdb instance.
###

_.bindAll pool, 'acquire', 'release'

run = (query) ->
    co -->
        connection = yield pool.acquire

        try
            result = yield query.run(connection)
            if result.toArray?
                result = yield result.toArray()
        finally
            pool.release(connection)

        return result

identity = (list = []) ->
    _.chain(list)
    .pluck('id')
    .sortBy(_.identity)
    .value()

describe 'mr.q', ->

    db    = r.db 'test'
    table = db.table 'mr'

    before co -->
        @timeout 4 * 1000
        try
            yield run db.tableDrop 'mr'
        catch e
            # nothing

        yield run db.tableCreate 'mr'
        yield run table.indexCreate 'dt'
        yield run table.indexCreate 'value'
        yield run table.insert fixture()

    describe 'simple value', ->

        it 'should $eq', co -->
            query  = mr.match {type: 'foo'}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([1, 2, 3])

        it 'should $between', co -->
            query  = mr.match {value: {$between: [3, 4]}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([3])

        it 'should $in', co -->
            query  = mr.match {name: {$in: ['foo1', 'bar1']}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([1, 4])

        it 'should $nin', co -->
            query  = mr.match {type: {$nin: ['foo']}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([4, 5])

        it 'should $contains', co -->
            query  = mr.match {list: {$contains: 'B'}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([3, 5])

        it 'should $gt', co -->
            query  = mr.match {value: {$gt: 2}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([3])

        it 'should $ge', co -->
            query  = mr.match {value: {$ge: 2}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([2, 3, 5])

        it 'should $lt', co -->
            query  = mr.match {value: {$lt: 2}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([1, 4])

        it 'should $le', co -->
            query  = mr.match {value: {$le: 2}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([1, 2, 4, 5])

    describe '$date', ->

        it 'should $eq', co -->
            query  = mr.match {dt: {$date: '2014-08-17 12:00:00'}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([1, 4])

        it 'should $between', co -->
            query  = mr.match {dt: {$between: [{$date: '2014-08-17 12:00:00'}, {$date: '2014-08-17 13:30:00'}]}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([1, 2, 4, 5])

    describe '$aggregate', ->

        it 'should $distinct', co -->
            query  = mr.aggregate {$distinct: 'type'}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(_.pluck(result, 'type')).to.deep.equal(['bar', 'foo'])

        it 'should $sum', co -->
            query  = mr.aggregate {$sum: 'value'}
            result = yield run query(table)

            expect(result).to.be.an('number')
            expect(result).to.deep.equal(9)

        it 'should $avg', co -->
            query  = mr.aggregate {$avg: 'value'}
            result = yield run query(table)

            expect(result).to.be.an('number')
            expect(result).to.deep.equal(1.8)

        it 'should $min', co -->
            query  = mr.aggregate {$min: 'value'}
            result = yield run query(table)

            expect(result).to.be.an('object')
            expect(result).to.have.property('value').that.equals(1)

        it 'should $max', co -->
            query  = mr.aggregate {$max: 'value'}
            result = yield run query(table)

            expect(result).to.be.an('object')
            expect(result).to.have.property('value').that.equals(3)

    describe 'mixed query', ->

        it 'should mixed filter', co -->
            query  = mr.match {type: 'foo', name: {$in: ['foo1', 'bar1']}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([1])

            query  = mr.match {type: 'foo', name: 'bar1'}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(result).to.have.length.of(0)

            query  = mr.match {type: 'foo', dt: {$between: [{$date: '2014-08-17 12:00:00'}, {$date: '2014-08-17 13:30:00'}]}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([1, 2])

        it 'should mixed filter with aggregate', co -->
            query  = mr.match {type: 'foo', name: {$in: ['foo1', 'bar1']}}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(identity(result)).to.deep.equal([1])

            query  = mr.match {type: 'foo', name: 'bar1'}
            result = yield run query(table)

            expect(result).to.be.an('array')
            expect(result).to.have.length.of(0)

            q1 = mr.match {type: {$in: ['foo', 'bar']}, dt: {$between: [{$date: '2014-08-17 12:00:00'}, {$date: '2014-08-17 13:30:00'}]}}
            q2 = mr.aggregate {$distinct: 'type'}
            result = yield run q2(q1(table))

            expect(result).to.be.an('array')
            .that.have.length.of(2)
