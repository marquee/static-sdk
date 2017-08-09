// @flow

const React  = require('react')
const _      = require("lodash")

// Use this on the root component of a HTMLView to inject
// the API data into the context
const provideAPIData = (dataRequirements) => (Component) => {

    class DataProvider extends React.Component {

        getChildContext() {
            return _.pick( this.props, _.keys(dataRequirements) )
        }

        render () {
            return React.createElement(Component, this.props)
            // return <Component {...this.props} />
        }
    }

    const ctx = _.mapValues(dataRequirements, (value, key, object) => {
                    return React.PropTypes.array
                })
    DataProvider.childContextTypes = ctx

    return DataProvider
}


// Wrap a child component in a tree that requires
// API data.
// @requiresAPIData({"sections" : React.PropTypes.array})

const requiresAPIData = (contextTypes) => (Komponent) => {
    class HasAPIData extends React.Component {
        render () {
            return React.createElement(Komponent, this.props)
            // return <Komponent {...this.props} {...this.context} />
        }
    }
    HasAPIData.contextTypes = contextTypes
    return HasAPIData
}


const reallyMapDataToProps = (data, dataRequirements) => {
    const {entries, topics, packages, people, locations} = data

    // TODO: This is will amount to a lot of unnecessary computation
    // this needs to be memoized.
    const packages_by_role  = packages.aggregatedBy('role')
    const people_by_role    = people.aggregatedBy('role')
    const locations_by_role = locations.aggregatedBy('role')
    const entries_by_role   = entries.aggregatedBy('role')
    const topics_by_role    = topics.aggregatedBy('role')

    const api_data_map = {
        entry    : {items : entries,   items_by_role : entries_by_role},
        package  : {items : packages,  items_by_role : packages_by_role},
        location : {items : locations, items_by_role : locations_by_role},
        topic    : {items : topics,    items_by_role : topics_by_role},
        person   : {items : people,    items_by_role : people_by_role}
    }

    return _.mapValues(dataRequirements, (value, key, object) => {
        if(null == value.type){
            throw new Error("Every value in the data requirements must be an object with a type key.")
        }

        if(!["entry", "package", "topic", "person", "location"].includes(value.type)){
            throw new Error(`${value.type} is not a supported API type`)
        }

        const {items, items_by_role} = api_data_map[value.type]

        if (null != value.role){
            return items_by_role[value.role] || []
        }else {
            return items
        }
    })
}



module.exports = {provideAPIData, requiresAPIData, reallyMapDataToProps}



// If the HTMLView component has a mapDataToProps to props
// add the data to it so it can be added to the context
// and child components can have access to the data
// if(null != _.get(Component, 'mapDataToProps')){
//     const f = _.wrap(Component.mapDataToProps, (func, args) => {
//         const retVal = func(args)
//         return {...retVal, data, dataRequirements}
//     })
//     Component.mapDataToProps = f
// }
