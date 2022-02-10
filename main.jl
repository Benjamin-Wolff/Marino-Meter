using HTTP
using Gumbo
using Cascadia
using Dates

LOCAL_MARINO = "./cache/localmarino.html"

function getMarinoData()
    url = "https://connect2concepts.com/connect2/?type=circle&key=2A2BE0D8-DF10-4A48-BEDD-B3BC0CD628E7"

    # Donwload the page
    open("./cache/localmarino.html", "w")
    download(url, LOCAL_MARINO)
end


function main()
    #getMarinoData()

    page = parsehtml(read(LOCAL_MARINO, String))
    locations = eachmatch(sel".col-md-3", page.root)

    entries = []

    for loc in locations
        floor_data = loc[1]

        name = floor_data[2][1]
        percent_full = round(parse(Float64, floor_data[1].attributes["data-percent"]), digits = 2)
        number = parse(Int, match(r"[0-9]+", floor_data[2][5].text).match)
        date = split(floor_data[2][7].text, " ")
        date = date[2] * " " * date[3] * " " * date[4]
        date_time = DateTime(date, "mm/dd/yyyy I:M p")

        append!(entries, (name, number, percent_full, date_time))
    end

    return entries
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

