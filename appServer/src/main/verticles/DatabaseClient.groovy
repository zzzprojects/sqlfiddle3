import io.vertx.groovy.ext.jdbc.JDBCClient
import io.vertx.core.impl.FutureImpl
import java.util.regex.Pattern

class DatabaseClient {
    static private jdbcConfig = [
        url: "jdbc:postgresql://appDatabase:5432/sqlfiddle",
        driver_class: "org.postgresql.Driver",
        user: "postgres",
        password: "password"
    ]
    static getConnection(vertx, fn) {
        JDBCClient
            .createShared(vertx, jdbcConfig, "SQLFiddle")
            .getConnection({ dbConnectionHandler ->
                if (dbConnectionHandler.succeeded()) {
                    fn(dbConnectionHandler.result())
                } else {
                    throw "Unable to get connection: " +
                        dbConnectionHandler.cause().getMessage()
                }
            })
    }

    static singleRead(vertx, query, params, fn) {
        getConnection(vertx, {connection ->
            connection.queryWithParams(query, params, {
                connection.close()
                def queryObj = queryResultAsBasicObj(it)
                if (queryObj.result && queryObj.result.size() == 1) {
                    fn(queryObj.result[0])
                } else {
                    throw new Exception(queryObj.message)
                }
            })
        })
    }

    static queryResultAsBasicObj(queryResult) {
        if (queryResult.succeeded()) {
            def columnNames = queryResult.result().columnNames
            return [
                result: queryResult.result().results.collect { row ->
                    def valueMap = [:]
                    columnNames.eachWithIndex { col, pos ->
                        valueMap[col] = row[pos]
                    }
                    return valueMap
                }
            ]
        } else {
            return [
                message: queryResult.cause().getMessage()
            ]
        }
    }

    static List<String> parseStatementGroups(String statements, String statement_separator, String batch_separator) {
        String newline = (char) 10
        String carrageReturn = (char) 13

        // run the provided ddl to setup the database environment...
        if (batch_separator && batch_separator.size()) {
            statements = statements.replaceAll(Pattern.compile(newline + batch_separator + carrageReturn + "?(" + newline + '|$)', Pattern.CASE_INSENSITIVE), statement_separator)
        }

        // this monster regexp parses the query block by breaking it up into statements, each with three groups -
        // 1) Positive lookbehind - this group checks that the preceding characters are either the start or a previous separator
        // 2) The main statement body - this is the one we execute
        // 3) The end of the statement, as indicated by a terminator at the end of the line or the end of the whole DDL
        return (Pattern.compile("(?<=(" + statement_separator + ")|^)([\\s\\S]*?)(?=(" + statement_separator + "\\s*\\n+)|(" + statement_separator + "\\s*\$)|\$)").matcher(statements))
            .findAll({
                return (it[0].size() && (it[0] =~ /\S/).find() )
            })
            .collect({
                return it[0]
            })
    }

    static executeSerially(connection, statements, successHandler, errorHandler) {
        def executeHandler
        executeHandler = { statementQueue ->
            if (statementQueue.size() == 0) {
                successHandler()
            } else {
                def statement = statementQueue.get(0)
                statementQueue.remove(0)
                connection.execute(statement, {
                    if (it.succeeded()) {
                        executeHandler(statementQueue)
                    } else {
                        errorHandler(it.throwable.getMessage())
                    }
                })
            }
        }
        executeHandler(statements)
    }


}
