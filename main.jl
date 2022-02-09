using HTTP
using Gumbo
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
    println(page.root)
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

