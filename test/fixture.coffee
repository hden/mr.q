'use strict'

module.exports = ->
    [
        {
            id: 1
            type: 'foo'
            name: 'foo1'
            value: 1
            list: []
            dt: new Date('2014-08-17 12:00:00')
        }
        {
            id: 2
            type: 'foo'
            name: 'foo2'
            value: 2
            list: ['A']
            dt: new Date('2014-08-17 13:00:00')
        }
        {
            id: 3
            type: 'foo'
            name: 'foo3'
            value: 3
            list: ['A', 'B']
            dt: new Date('2014-08-17 14:00:00')
        }
        {
            id: 4
            type: 'bar'
            name: 'bar1'
            value: 1
            list: ['A', 'C']
            dt: new Date('2014-08-17 12:00:00')
        }
        {
            id: 5
            type: 'bar'
            name: 'bar2'
            value: 2
            list: ['B', 'C']
            dt: new Date('2014-08-17 13:00:00')
        }
    ]
