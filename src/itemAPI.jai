/* EXAMPLE
[
    {
        "id": "caldarr-fusion-material-2",
        "gameCode": "6861010",
        "name": "Caldarr Fusion Material",
        "image": "https://www.lostarkmarket.online/assets/item_icons/caldarr-fusion-material.webp",
        "avgPrice": 3,
        "lowPrice": 5,
        "recentPrice": 5,
        "cheapestRemaining": 266,
        "amount": 1,
        "rarity": 2,
        "category": "Enhancement Material",
        "subcategory": "Honing Materials",
        "shortHistoric": {
            "2023-07-07": 4.12,
            "2023-07-06": 5.76,
            "2023-07-12": 4.5,
            "2023-07-11": 3.76,
            "2023-07-10": 3.3,
            "2023-07-09": 5.17,
            "2023-07-08": 4.55
        },
        "updatedAt": "2023-07-12T17:44:49.373Z"
    }
]
*/

Market_Item :: struct
{
    id: string;
    game_code: string; @rename("gameCode")
    name: string;
    image: string;
    avg_price: float; @rename("avgPrice")
    low_price: float; @rename("lowPrice")
    recent_price: float; @rename("recentPrice")
    cheapest_remaining: int; @rename("cheapestRemaining") 
    amount: int;
    rarity: int;
    category: string;
    subcategory: string;
    //short_historic: Table(string, float); @rename("shortHistoric")     
    //updated_at: string; @rename("updatedAt")
}