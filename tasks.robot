*** Settings ***
Documentation       Rotten Tomato Automation
Library    RPA.Browser.Selenium
Library    String
Library    Collections
Library    DatabaseLibrary
Library    RPA.Tables
Library    RPA.Excel.Files
Library    remove_extra.py
Resource    database.robot
Library    BuiltIn

*** Variables ***
${BASE_URL}=    https://www.rottentomatoes.com/search?search=
${match_link}=    ${None}
${TABLE_NAME}=    movies
${DBName}         moviesInfo

*** Tasks ***
Automate 
    ${search_values}=    Read excel file to get movie list
    Open Available Browser 
    Maximize Browser Window
    FOR    ${search_value}    IN    @{search_values}
        ${search_value}=    Set Variable    ${search_value}[Movie]
        Open browser and search    ${search_value}
        ${search_results}=    extract similar movies    ${search_value}
        ${match_link}=    Find match and navigate if found    ${search_results}    ${search_value}
        IF    '${match_link}' != '${None}'
            navigate to movie    ${match_link} 
            ${movie_info}=    Get movie detail    ${search_value}  
        ELSE
            ${status}=    Set Variable    No exact match found
            ${movie_info}=    Create Dictionary    
            ...    title=${search_value}
            ...    status=${status}
        END
        Log    ${movie_info}
        establish connection
        TRY
            Table Must Exist    movies
        EXCEPT    Table 'movies' does not exist in the db
            Create table movie
        FINALLY
            Insert data into tables    ${movie_info}    ${TABLE_NAME}
        END
    END
    



*** Keywords ***
Read excel file to get movie list
    Open Workbook    movies.xlsx
    ${search_values}    Read Worksheet As Table    header=True
    Close Workbook
    RETURN    ${search_values}

Open browser and search
    [Arguments]    ${search_value}
    Go To    ${BASE_URL}${search_value}
    Click Element    
    ...    xpath://li[@data-filter='movie']

extract similar movies
    [Arguments]    ${search_value}
    Wait Until Element Is Visible    
    ...    xpath://search-page-result[@type='movie']//ul[@slot='list']
    ${search_results}=    Get WebElements    
    ...    xpath://search-page-result[@type='movie']//ul[@slot='list']//a[@class='unset']
    RETURN    ${search_results}
    
Find match and navigate if found
    [Arguments]    ${search_results}    ${search_value}
    FOR    ${search_result}    IN    @{search_results}[1:] 
        ${text}=    Set Variable    nothing 
        ${text}=    Get Text    ${search_result}
        ${text}=    Convert To Lower Case    ${text}
        ${search_value}=    Convert To Lower Case    ${search_value}
        IF    '${text}' == '${search_value}'
            ${match_link}=    Get Element Attribute    ${search_result}    href
            BREAK
        END
    END
    RETURN    ${match_link}

navigate to movie    
    [Arguments]    ${match_link}
    Go To    ${match_link}

Get movie detail
    [Arguments]    ${search_value} 
    ${status}=    Set Variable    Sucsess
    Wait Until Element Is Visible    id:topSection
    Sleep    1s
    ${title}=    Get Text    
    ...    xpath:/html/body/div[3]/main/div/section/div[2]/section[1]/div[1]/score-board/h1
    ${tomatometer_score}=    Get Element Attribute    
    ...    xpath=//score-board[@data-qa="score-panel"]    
    ...    tomatometerscore
    ${audience_score}=       Get Element Attribute    
    ...    xpath=//score-board[@data-qa="score-panel"]    
    ...    audiencescore
    ${rating}=               Get Element Attribute    
    ...    xpath=//score-board[@data-qa="score-panel"]    
    ...    rating
    ${tomatometerstate}=     Get Element Attribute    
    ...    xpath=//score-board[@data-qa="score-panel"]    
    ...    tomatometerstate
    
    
    Wait Until Element Is Visible    id:movie-info
    ${story_line}=    
    ...    Get Text    
    ...    xpath://p[@data-qa='movie-info-synopsis']
    ${genres}=    
    ...    Get Text    
    ...    xpath://*[@id="info"]/li[1]/p/span

    Wait Until Element Is Visible    id:critics-reviews
    ${review_ballon_list}=    Get WebElements    xpath://review-speech-balloon[@data-qa="critic-review"]
    ${review_quotes}=    Create Dictionary
    ${review_count}=    Set Variable    1
    FOR    ${review}    IN    @{review_ballon_list}
        ${review_quote}=    Get Element Attribute    ${review}    reviewquote
        ${review_quote}=    Remove Punctuations    ${review_quote}
        Set To Dictionary    ${review_quotes}    review_${review_count}    ${review_quote}
        ${review_count}=    Evaluate    ${review_count}+1
        Run Keyword If    ${review_count} > 5    Exit For Loop
    END
    WHILE    ${review_count} <= 5
        Set To Dictionary    
        ...    ${review_quotes}    
        ...    review_${review_count}    
        ...    ${None}
        ${review_count}=    Evaluate    
        ...    ${review_count}+1
    END    
    ${value_dict}=    Create Dictionary    
    ...    title=${title}    
    ...    tomatometer_score=${tomatometer_score}
    ...    audience_score=${audience_score}
    ...    rating=${rating}
    ...    tomatometerstate=${tomatometerstate}
    ...    story_line=${story_line}
    ...    genres=${genres}
    ...    reviews_1=${review_quotes}[review_1]
    ...    reviews_2=${review_quotes}[review_2]
    ...    reviews_3=${review_quotes}[review_3]
    ...    reviews_4=${review_quotes}[review_4]
    ...    reviews_5=${review_quotes}[review_5]
    ...    status=${status}   
    RETURN    ${value_dict}


Remove Punctuations
    [Arguments]    ${string}
    ${pattern}=    Set Variable    [\"']
    ${result}=     Replace String Using Regexp    ${string}    ${pattern}    ${EMPTY}
    [Return]    ${result}


establish connection
    Connect To Database Using Custom Params    
    ...    sqlite3    
    ...    database="./${DBName}.db", isolation_level=None
    
Create table movie
    ${create_table_sql} =    Catenate    SEPARATOR=    \n
    ...    CREATE TABLE movies(
    ...        id INTEGER PRIMARY KEY AUTOINCREMENT,
    ...        title TEXT ,
    ...        tomatometer_score TEXT,
    ...        tomatometerstate TEXT,
    ...        audience_score TEXT,
    ...        story_line TEXT,
    ...        rating TEXT,
    ...        genres TEXT,
    ...        reviews_1 TEXT,
    ...        reviews_2 TEXT,
    ...        reviews_3 TEXT,
    ...        reviews_4 TEXT,
    ...        reviews_5 TEXT,
    ...        status TEXT
    ...    );
    Execute Sql String    ${create_table_sql}

Insert data into tables
    [Arguments]    ${data_dict}    ${table_name}
    ${data_dict}=    Evaluate    {k: "Not Found" if not v else v for k, v in ${data_dict}.items() }
    ${keys}=  Get Dictionary Keys  ${data_dict}
    ${values}=  Get Dictionary Values  ${data_dict}
    ${columns}=    Evaluate    ", ".join(${keys})
    ${placeholders}=    Evaluate      ("\'"+"\', \'".join(${values})) +"\'"
    ${query}=    Set Variable    INSERT INTO ${table_name} (${columns}) VALUES (${placeholders});
    Run Keyword And Ignore Error    Execute Sql String    ${query}
