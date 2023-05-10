*** Settings ***
Documentation    Connect to database and insert values
Library    DatabaseLibrary
Library    RPA.Tables
Library    Collections
Resource    tasks.robot
*** Variables ***
${DBName}         moviesInfo


*** Tasks ***

*** Keywords ***
establish connection
    Connect To Database Using Custom Params    
    ...    sqlite3    
    ...    database="./${DBName}.db", isolation_level=None
    
Create table movie
    ${create_table_sql} =    Catenate    SEPARATOR=    \n
    ...    CREATE TABLE movies(
    ...        id INTEGER PRIMARY KEY AUTOINCREMENT,
    ...        movie_name TEXT NOT NULL,
    ...        tomatometer_score TEXT NOT NULL,
    ...        audience_score TEXT NOT NULL,
    ...        storyline TEXT NOT NULL,
    ...        rating TEXT NOT NULL,
    ...        genres TEXT NOT NULL,
    ...        review_1 TEXT,
    ...        review_2 TEXT,
    ...        review_3 TEXT,
    ...        review_4 TEXT,
    ...        review_5 TEXT,
    ...        status TEXT NOT NULL
    ...    );
    Execute Sql String    ${create_table_sql}

Insert data into tables
    [Arguments]    ${data_dict}    ${table_name}
    ${data_dict}=    Evaluate    {k: "Not Found" if not v else v for k, v in ${data_dict}.items() }
    ${keys}=  Get Dictionary Keys  ${data_dict}
    ${values}=  Get Dictionary Values  ${data_dict}
    ${columns}=    Evaluate    ", ".join(${keys})
    ${placeholders}=    Evaluate      ('\"'+'\", \"'.join(${values})) +'\"'
    ${query}=    Set Variable    INSERT INTO ${table_name} (${columns}) VALUES (${placeholders});
    Execute Sql String    ${query}
