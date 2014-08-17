'use strict'

debug = require('debug')('mr')
_     = require 'underscore'
r     = require 'rethinkdb'
walk  = require 'traverse'

expr = [
    '$date'
    '$between'
    '$in'
    '$nin'
    '$contains'
    '$gt'
    '$ge'
    '$lt'
    '$le'
    '$eq'
]

regex = /^\$/

isExpr = (ast = {}) ->
    return false unless _.isObject ast
    keys = _.keys(ast)
    return false unless keys.length is 1
    return false unless regex.test keys[0]

    true

rewrite = (ast = {}) ->
    ast = _.clone ast

    walk(ast).map (node) ->
        if @key is '$date'
            @parent.update new Date(node)

exports.match = (ast = {}) ->

    ast = rewrite ast

    partial = _.chain(ast)
    .pairs()
    .map ([left, value]) ->
        if isExpr value
            op = _.keys(value)[0]
            throw new Error "unknown expression #{key}" unless op in expr
            {left, op, right: value[op]}
        else
            {left, op: '$eq', right: value}
    .groupBy('op')
    .value()

    (seq) ->
        # between 2nd index
        partial.$between?.forEach ({left, op, right}) ->
            throw new Error 'invalid $between expr' unless _.isArray right
            throw new Error 'invalid $between expr' unless right.length is 2
            seq = seq.between right[0], right[1], {index: left}

        # range
        partial.$in?.forEach ({left, op, right}) ->
            throw new Error 'invalid $in expr' unless _.isArray right
            seq = seq.filter (row) ->
                r.expr(right).contains(row(left))

        partial.$nin?.forEach ({left, op, right}) ->
            throw new Error 'invalid $in expr' unless _.isArray right
            seq = seq.filter (row) ->
                r.expr(right).contains(row(left)).not()

        partial.$contains?.forEach ({left, op, right}) ->
            seq = seq.filter (row) ->
                row(left).contains(right)

        # math
        partial.$gt?.forEach ({left, op, right}) ->
            seq = seq.filter (row) ->
                row(left).gt(right)

        partial.$ge?.forEach ({left, op, right}) ->
            seq = seq.filter (row) ->
                row(left).ge(right)

        partial.$lt?.forEach ({left, op, right}) ->
            seq = seq.filter (row) ->
                row(left).lt(right)

        partial.$le?.forEach ({left, op, right}) ->
            seq = seq.filter (row) ->
                row(left).le(right)

        # exact match
        $eq = {}
        partial.$eq?.forEach ({left, op, right}) ->
            $eq[left] = right

        seq = seq.filter $eq

        seq

exports.aggregate = (ast) ->

    throw new Error 'invalid aggregator' unless _.isObject ast
    keys = _.keys ast
    throw new Error 'multiple aggregator' unless keys.length is 1
    op  = keys[0]
    key = ast[op]

    (seq) ->

        throw new Error "unknown aggregator #{op}" unless op in ['$distinct', '$sum', '$avg', '$min', '$max']

        op = op.replace '$', ''
        if op is 'distinct'
            seq = _.result(seq.withFields(key), op)
        else
            seq = seq[op](key)

        seq
