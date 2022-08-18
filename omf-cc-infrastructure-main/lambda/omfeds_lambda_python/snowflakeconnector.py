from snowflake.connector import connect, ProgrammingError
from typing import List

class SnowflakeConnector(object):

    def __init__(self, **kwargs) -> None:
        self.snowflake_user = kwargs.get("snowflake_user")
        self.snowflake_password = kwargs.get("snowflake_password")
        self.snowflake_account_identifier = kwargs.get("snowflake_account_identifier")
        self.snowflake_source_database = kwargs.get("snowflake_source_database")
        self.snowflake_source_schema = kwargs.get("snowflake_source_schema")
        self.snowflake_warehouse = kwargs.get("snowflake_warehouse")
        self.snowflake_role = kwargs.get("snowflake_role")
        self.snowflake_connection = self._create_connection()

    def _create_connection(self):
        """Return a Snowflake connection with the attributes"""
        return connect(
            user=self.snowflake_user,
            password=self.snowflake_password,
            account=self.snowflake_account_identifier,
            database=self.snowflake_source_database,
            schema=self.snowflake_source_schema,
            warehouse=self.snowflake_warehouse,
            role=self.snowflake_role
        )

    def execute_query_async(self, query):
        """Execute query async and return query id"""
        cursor = self.snowflake_connection.cursor().execute_async(query)
        return cursor.sfqid

    def execute_stored_procedure(self, query) -> List:
        """Execute specific store procedure and return result"""
        cursor = self.execute_query(query)
        result = cursor.fetchall()
        return result

    def execute_query(self, query):
        """Execute query synchronously"""
        cursor = self.snowflake_connection.cursor().execute(query)
        return cursor

    @staticmethod
    def check_async_query_status_throw_if_error(connection: connect, query_id):
        return connection.get_query_status_throw_if_error(query_id)
