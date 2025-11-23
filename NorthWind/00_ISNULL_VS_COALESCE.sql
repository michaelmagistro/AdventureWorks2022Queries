-- Comparison query showing both side by side
SELECT 
    OrderID,
    CustomerID,
    ShipRegion,
    ShipCountry,
    ShipPostalCode,
    COALESCE(ShipRegion, ShipCountry, ShipPostalCode, 'Unknown') AS Using_COALESCE, -- Coalesce functions as a "fallback"; if ShipRegion is null, use ShipCountry, if that is NULL, use 'Unknown' and so forth.
    ISNULL(ShipRegion, 'Unknown') AS Using_ISNULL -- Return ShipRegion; unless NULL, then 'Unknown'
FROM Orders 

-- Key Differences:
-- ISNULL: Only two arguments, treats as single type (can cause issues with data types).
-- COALESCE: Variable arguments, more flexible, but evaluates all (performance note for functions).


-- How ISNULL can cause issues with data types
-- ISNULL truncates 'Unknown Location' to fit VARCHAR(15) → 'Unknown Locati'
SELECT ISNULL(ShipRegion, 'Unknown Location') AS BadISNULL
FROM Orders 
WHERE ShipRegion IS NULL;

-- COALESCE uses the "best" type among arguments (here, fits full string)
SELECT COALESCE(ShipRegion, 'Unknown Location') AS GoodCOALESCE
FROM Orders 
WHERE ShipRegion IS NULL;