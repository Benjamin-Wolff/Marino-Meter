#!/usr/bin/env julia

using HTTP
using Gumbo
using Cascadia
using Dates
using PrettyPrint
using Mongoc
using ArgParse

#=

/\/\__________      ___.           __    __________                       _____/\/\                
)/)/\______   \ ____\_ |__   _____/  |_  \______   \_______  ____   _____/ ____)/)/                
     |       _//  _ \| __ \ /  _ \   __\  |     ___/\_  __ \/  _ \ /  _ \   __\                    
     |    |   (  <_> ) \_\ (  <_> )  |    |    |     |  | \(  <_> |  <_> )  |                      
     |____|_  /\____/|___  /\____/|__|    |____|     |__|   \____/ \____/|__|                      
            \/           \/                                                                        
                                                                       _____                       
                                                                      /  _  \   ____  __ __  ____  
                                                            ______   /  /_\  \ /  _ \|  |  \/    \ 
                                                           /_____/  /    |    (  <_> )  |  /   |  \
                                                                    \____|__  /\____/|____/|___|  /
                                                                            \/                  \/ 

=#

LOCAL_MARINO = "./cache/localmarino.html"
MARINO_URL = "https://connect2concepts.com/connect2/?type=circle&key=2A2BE0D8-DF10-4A48-BEDD-B3BC0CD628E7"
LOCATION_NAMES = ["sb-4", "m-2", "m-tr", "m-g", "m-wr", "m-3"]


# parse the command line (just for the password, which we don't wish to store online)
function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--password"
        help = "password for the MongoDB user (it's a seeecret shh!)"
        "--cert"
        help = "path to root cert.pem"
        default = "/usr/local/etc/ca-certificates/cert.pem"
    end

    return parse_args(s)
end

# downloads the marino page into the given path
function getMarinoPage(path)
    # Download the page
    open(path, "w")
    download(MARINO_URL, path)
end

# parses the Marino page
function parseMarinoData(path)
    page = parsehtml(read(path, String))
    locations = eachmatch(sel".col-md-3", page.root)

    name_conversion = Dict(
        "SquashBusters - 4th Floor" => "sb-4",
        "Marino Center - 2nd Floor" => "m-2",
        "Marino Center - Track" => "m-tr",
        "Marino Center - Gymnasium" => "m-g",
        "Marino Center - 3rd Floor Weight Room" => "m-wr",
        "Marino Center - 3rd Floor Select & Cardio" => "m-3"
    )

    marino_data = []

    for loc in locations
        floor_data = loc[1]

        name = floor_data[2][1].text
        percent_full = round(parse(Float64, floor_data[1].attributes["data-lastcount"]), digits = 2)
        number = parse(Int, match(r"[0-9]+", floor_data[2][5].text).match)
        date = split(floor_data[2][7].text, " ")
        date = date[2] * " " * date[3] * " " * date[4]
        date_time = DateTime(date, "mm/dd/yyyy I:M p")

        entry = Dict("name" => name_conversion[name], "number" => number, "percent_full" => percent_full, "date_time" => date_time)
        push!(marino_data, entry)
    end

    return marino_data
end

# sends the Marino data to the MongoDB
function storeMarinoData(marino_data, password, cert_path)
    # THIS ISSUE WHERE WE NEEDED A SUFFIX TO CONNECT TO MONGODB TOOK LIKE A FEW HOURS TO FIGURE OUT
    suffix = "&tlsCAFile=$cert_path"
    client = Mongoc.Client("mongodb+srv://root:$password@marinobase.vunm9.mongodb.net/umongo?retryWrites=true&w=majority" * suffix)
    
    database = client["Umongo"]
    @info "Succesfully connected to Umongo ;)"
    collection = database["GymData"]

    for entry in marino_data
        name = entry["name"]
        new_date = entry["date_time"]
        bson_filter = Mongoc.BSON("""{ "name" : "$name" }""")
        bson_options = Mongoc.BSON("""{ "sort" : { "date_time" : -1 } }""")
        doc = Mongoc.find_one(collection, bson_filter, options=bson_options)
        
        doc_date = nothing
        if !isnothing(doc)
            doc_date = doc["date_time"]
        end

        if isnothing(doc) || new_date > doc_date 
            document = Mongoc.BSON(entry)
            result = Mongoc.insert_one(collection, document)
            @info "New member inserted into Umongo with result: $result"   
        end     
    end
end

function main()
    parsed_args = parse_commandline()
    getMarinoPage(LOCAL_MARINO)
    marino_data = parseMarinoData(LOCAL_MARINO)
    @info "Marino Data Obtained from the page"
    storeMarinoData(marino_data, parsed_args["password"], parsed_args["cert"])

    #queryTest()
end

main()

#=

{
marino-2 {
    percent: 50%,
    count: 5,
    datetime: 02/09/2022 05:27 PM
}
marino-wr {
    percent: 50%,
    count: 5,
    datetime: 02/09/2022 05:27 PM
}
.
.
.
}

=#