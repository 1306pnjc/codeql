/**
 * Provides classes for working with Apollo GraphQL connectors.
 */

import javascript

/** Provides classes modeling the apollo packages [@apollo/server](https://npmjs.com/package/@apollo/server`) */
module Apollo {
  /** Get an instanceof of `Apollo` */
  private API::Node apollo() {
    result =
      API::moduleImport([
          "@apollo/server", "@apollo/apollo-server-express", "@apollo/apollo-server-core",
          "apollo-server", "apollo-server-express"
        ]).getMember("ApolloServer")
  }

  /** Get an instanceof of the `gql` function that parses GraphQL strings. */
  private API::Node gql() {
    result =
      API::moduleImport([
          "@apollo/server", "@apollo/apollo-server-express", "@apollo/apollo-server-core",
          "apollo-server", "apollo-server-express"
        ]).getMember("gql")
  }

  /** A string that is interpreted as a GraphQL query by a `graphql` package. */
  class ApolloServer extends API::NewNode {
    ApolloServer() { this = apollo().getAnInstantiation() }
  }

  /** A string that is interpreted as a GraphQL query by a `apollo` package. */
  class ApolloGraphQLString extends GraphQL::GraphQLString {
    ApolloGraphQLString() { this = gql().getACall().getArgument(0) }
  }
}
