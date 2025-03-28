-- SORU 1: 
-- Northwind veritabanında toplam kaç tablo vardır? Bu tabloların isimlerini listeleyiniz.

-- TABLO SAYISI
SELECT COUNT(*) AS TABLE_COUNT 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

-- TABLO İSİMLERİ
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

GO

-- ******************************************************************************************

--SORU 2:
-- Her sipariş (Orders) için, Şirket adı (CompanyName), çalışan adı (Employee Full Name), sipariş tarihi ve
-- gönderici şirketin adı (Shipper) ile birlikte bir liste çıkarın.

SELECT o.OrderID, c.CompanyName, 
	CONCAT(e.FirstName, ' ', e.LastName) AS Employee_Full_Name, 
	o.OrderDate, s.CompanyName AS Shipping_Company_Name
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Employees e ON o.EmployeeID = e.EmployeeID
JOIN Shippers s ON o.ShipVia = s.ShipperID;
GO

-- ******************************************************************************************

-- Soru 3: Aggregate Fonksiyon:  Tüm siparişlerin toplam tutarını bulun. (Order Details tablosundaki Quantity UnitPrice üzerinden hesaplayınız.

SELECT  SUM(Quantity * UnitPrice) AS Total_Price FROM [Order Details];
GO

-- ******************************************************************************************

-- Soru 4: Gruplama: Hangi ülkeden kaç müşteri vardır?

SELECT Country, COUNT(*) AS Total_Customers 
FROM Customers
GROUP BY Country;
GO

-- ******************************************************************************************

-- Soru 5: Subquery Kullanımı: En pahalı ürünün adını ve fiyatını listeleyiniz. 

SELECT ProductName, UnitPrice
FROM Products 
WHERE UnitPrice = (SELECT MAX(UnitPrice) FROM Products);
GO

-- ******************************************************************************************

-- Soru 6: JOIN ve Aggregate: Çalışan başına düşen sipariş sayısını gösteren bir liste çıkarınız.


SELECT e.EmployeeID, CONCAT(e.FirstName, ' ', e.LastName) AS Employee_Full_Name,
		COUNT(OrderID) AS Order_Count
FROM Employees e
LEFT JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName;
GO

-- ******************************************************************************************

-- Soru 7: Tarih Filtreleme: 1997 yılında verilen siparişleri listeleyin.

SELECT *
FROM Orders
WHERE YEAR(OrderDate) = 1997;
GO

-- ******************************************************************************************

-- Soru 8: CASE Kullanımı: Ürünleri fiyat aralıklarına göre kategorilere ayırarak listeleyin: 020 → Ucuz, 2050 → Orta, 50+ → Pahalı.

SELECT ProductName, UnitPrice,
CASE
	WHEN UnitPrice BETWEEN 0 AND 20 THEN 'Ucuz'
	WHEN UnitPrice BETWEEN 20 AND 50 THEN 'Orta'
	WHEN UnitPrice > 50 THEN 'Pahalı'
END AS Product_Price_Category
FROM Products;
GO

-- ******************************************************************************************

-- Soru 9: Nested Subquery: En çok sipariş verilen ürünün adını ve sipariş adedini (adet bazında) bulun.

SELECT ProductName, Total_Quantity
FROM (
    SELECT p.ProductName, SUM(od.Quantity) AS Total_Quantity
    FROM [Order Details] od
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY p.ProductName
) AS Sub
WHERE Total_Quantity = (
    SELECT MAX(Total_Quantity)
    FROM (
        SELECT SUM(Quantity) AS Total_Quantity
        FROM [Order Details]
        GROUP BY ProductID
    ) AS Totals
);
GO

-- ******************************************************************************************

-- Soru 10: View Oluşturma: Ürünler ve kategoriler bilgilerini birleştiren bir görünüm (view) oluşturun.

CREATE VIEW ProductCategoryView AS
SELECT p.ProductID, p.ProductName, p.UnitPrice, c.CategoryName, c.Description
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID;
GO

SELECT * FROM ProductCategoryView;
GO

-- ******************************************************************************************

-- Soru 11: Trigger: Ürün silindiğinde log tablosuna kayıt yapan bir trigger yazınız.

CREATE TABLE ProductDeletionLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    ProductName NVARCHAR(100),
    DeletedDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TRIGGER trg_ProductDeletion
ON Products
AFTER DELETE
AS
BEGIN
    INSERT INTO ProductDeletionLog (ProductID, ProductName)
    SELECT ProductID, ProductName FROM deleted;
END;
GO

DELETE FROM [Order Details] WHERE ProductID = 1;
DELETE FROM Products WHERE ProductID = 1;
SELECT * FROM ProductDeletionLog;
GO

-- ******************************************************************************************

-- Soru 12: Stored Procedure: Belirli bir ülkeye ait müşterileri listeleyen bir stored procedure yazınız

CREATE PROCEDURE sp_GetCustomersByCountry
    @Country NVARCHAR(50)
AS
BEGIN
    SELECT * FROM Customers WHERE Country = @Country;
END;
GO

EXEC sp_GetCustomersByCountry @Country = 'Germany';
GO

-- ******************************************************************************************

-- Soru 13: Left Join Kullanımı: Tüm ürünlerin tedarikçileriyle (suppliers) birlikte listesini yapın. Tedarikçisi olmayan ürünler de listelensin.

SELECT p.ProductName, s.CompanyName AS Supplier_Name
FROM Products p
LEFT JOIN Suppliers s ON p.SupplierID = s.SupplierID;
GO

-- ******************************************************************************************

-- Soru 14: Fiyat Ortalamasının Üzerindeki Ürünler: Fiyatı ortalama fiyatın üzerinde olan ürünleri listeleyin.

SELECT ProductName, UnitPrice FROM Products
WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM Products);
GO

-- ******************************************************************************************

-- Soru 15: En Çok Ürün Satan Çalışan: Sipariş detaylarına göre en çok ürün satan çalışan kimdir?

SELECT TOP 1 e.EmployeeID, CONCAT(e.FirstName, ' ', e.LastName) AS Employee_Full_Name, SUM(od.Quantity) AS Total_Products_Sold
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER BY Total_Products_Sold DESC;
GO

-- ******************************************************************************************

-- Soru 16: Ürün Stoğu Kontrolü: Stok miktarı 10’un altında olan ürünleri listeleyiniz.

SELECT ProductID, ProductName, UnitsInStock FROM Products
WHERE UnitsInStock < 10;
GO

-- ******************************************************************************************

-- Soru 17: Şirketlere Göre Sipariş Sayısı: Her müşteri şirketinin yaptığı sipariş sayısını ve toplam harcamasını bulun.

SELECT c.CustomerID, 
	   c.CompanyName, 
	   COUNT(o.OrderID) AS Order_Count, 
	   SUM(od.Quantity * od.UnitPrice) AS Total_Spending
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CompanyName
GO

-- ******************************************************************************************

-- Soru 18: En Fazla Müşterisi Olan Ülke: Hangi ülkede en fazla müşteri var?

SELECT TOP 1 Country, COUNT(DISTINCT CustomerID) AS Customer_Count
FROM Customers
GROUP BY Country
ORDER BY Customer_Count DESC;
GO

-- ******************************************************************************************

-- Soru 19: Her Siparişteki Ürün Sayısı: Siparişlerde kaç farklı ürün olduğu bilgisini listeleyin.

SELECT OrderID, COUNT(DISTINCT ProductID) AS Unique_Product_Count
FROM [Order Details]
GROUP BY OrderID;
GO

-- ******************************************************************************************

-- Soru 20: Ürün Kategorilerine Göre Ortalama Fiyat: Her kategoriye göre ortalama ürün fiyatını bulun

SELECT c.CategoryName, AVG(p.UnitPrice) AS AveragePrice
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName;
GO

-- ******************************************************************************************

-- Soru 21: Aylık Sipariş Sayısı: Siparişleri ay ay gruplayarak kaç sipariş olduğunu listeleyin.

SELECT MONTH(OrderDate) AS Order_Month, 
       YEAR(OrderDate) AS Order_Year, 
	   COUNT(OrderID) AS Order_Count
FROM Orders
GROUP BY MONTH(OrderDate), YEAR(OrderDate)
ORDER BY Order_Year, Order_Month;
GO

-- ******************************************************************************************

-- Soru 22: Çalışanların Müşteri Sayısı: Her çalışanın ilgilendiği müşteri sayısını listeleyin.

SELECT e.EmployeeID, 
       CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeFullName, 
	   COUNT(DISTINCT o.CustomerID) AS CustomerCount
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName;
GO

-- ******************************************************************************************

-- Soru 23: Hiç siparişi olmayan müşterileri listeleyin.

SELECT c.CustomerID, c.CompanyName 
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;
GO


-- ******************************************************************************************

-- Soru 24: Siparişlerin Nakliye (Freight) Maliyeti Analizi: Nakliye maliyetine göre en pahalı 5 siparişi listeleyin.

SELECT TOP 5 OrderID, Freight
FROM Orders
ORDER BY Freight DESC;
GO