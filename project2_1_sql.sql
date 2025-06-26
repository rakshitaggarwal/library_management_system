--CRUD OPERATIONS 
--1) Create a new book record -- "978-1-60129-456-2, 'To Kill a Mockingbird' , 'classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.'"
INSERT INTO books
(isbn,book_title,category,rental_price,status,author,publisher)
VALUES('978-1-60129-456-2','To Kill a Mockingbird','Classic',6.00,'yes','Harper Lee','J.B. Lippincott & Co.')
SELECT * FROM books 

--2) UPDATE existing member address 

UPDATE members 
SET member_address = '124 Main St'
WHERE member_id='C101'
select * from members

--3) Delete a record from issued_status table . delete record with issued_id='IS121' 
select * from issued_status
DELETE FROM issued_status
where issued_id ='IS121' 

--4) Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

select issued_book_name from issued_status
where issued_emp_id ='E101'
	
--5) List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT * FROM members 
SELECT * FROM (
SELECT issued_member_id,count(issued_book_name) as no_of_books FROM issued_status
group by issued_member_id )
WHERE no_of_books > 1

--OR 
SELECT
    issued_member_id,
    COUNT(*)
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1

--Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
CREATE TABLE book_issued_cnt AS 
SELECT isbn,book_title,count(issued_id) as no_of_issued
from books as b  
join issued_status as ist 
on b.isbn=ist.issued_book_isbn
group by 1,2

select * from book_issued_cnt

--Data Analysis and findings
--1.Retrieve All Books in a Specific Category
select * from books where category='Fantasy'

--2.Find Total Rental Income by Category
select category,sum(rental_price) as Total_rent from books
group by 1 

--3.List Members Who Registered in the Last 360 Days
select *  from members 
where reg_date >= CURRENT_DATE - INTERVAL '360 days'

--4.List Employees with Their Branch Manager's Name and their branch details
SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name as manager
FROM employees as e1
JOIN 
branch as b
ON e1.branch_id = b.branch_id    
JOIN
employees as e2
ON e2.emp_id = b.manager_id

--5.Create a Table of Books with Rental Price Above a Certain Threshold
create table expensive_books as 
select * from books
where rental_price>7

--6.Retrieve the List of Books Not Yet Returned
select issued_book_name from issued_status  as ist
left join return_status as rs 
on ist.issued_id=rs.issued_id
where rs.return_id is null


--Advanced SQL operations
--1)  Identify Members with Overdue Books
--Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
select ist.issued_member_id,m.member_name,bk.book_title,ist.issued_date,current_date - ist.issued_date as overdue from issued_status as ist
join members as m 
on ist.issued_member_id=m.member_id 
join books as bk 
on ist.issued_book_isbn=bk.isbn	
left join return_status as rs 
on ist.issued_id=rs.issued_id
where rs.return_date is null
and 
(current_date - ist.issued_date) > 90
order by 1

--2)Update Book Status on Return
--Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

--Store Procedures 
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10),p_issued_id VARCHAR(10),p_book_quality VARCHAR(15))
LANGUAGE plpgsql
AS $$ 

DECLARE 
	v_isbn VARCHAR(20);
	v_book_name VARCHAR(60);


BEGIN 
	--all logic and code here 
	--inserting into returns based on user input
	INSERT INTO return_status(return_id,issued_id,return_date,book_quality)
	VALUES (p_return_id,p_issued_id,CURRENT_DATE,p_book_quality);

	SELECT 
		issued_book_isbn ,
		issued_book_name
		INTO 
		v_isbn,
		v_book_name
	from issued_status
	where issued_id=p_issued_id;

	UPDATE books 
	SET status='yes'
	WHERE isbn=v_isbn;
	RAISE NOTICE 'Thank You for returning the book: %',v_book_name;
END;
$$
--testing function add_return_records
issued_id=IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

select * from books
where isbn='978-0-307-58837-1'

select * from issued_status 
where issued_book_isbn='978-0-307-58837-1'

select * from return_status
where issued_id = 'IS135'

--calling function 
CALL add_return_records('RS138','IS135','Good');

CALL add_return_records('RS148','IS134','Good');


--3) Branch Performance Report
--Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

CREATE TABLE branch_report 
AS
SELECT
	b.branch_id,
	COUNT(ist.issued_id) as number_books_issued,
	COUNT(rs.return_id) as number_books_returned,
	SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN employees as e 
ON ist.issued_emp_id=e.emp_id
JOIN branch as b 
ON b.branch_id=e.branch_id
LEFT JOIN return_status as rs
ON rs.issued_id=ist.issued_id
JOIN books as bk
ON bk.isbn=ist.issued_book_isbn
GROUP BY 1
 
select * from branch_report 

--4)Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
CREATE TABLE active_members
AS 
SELECT * FROM  members
WHERE  member_id IN (
		SELECT DISTINCT issued_member_id 
		FROM  issued_status
		WHERE issued_date >= CURRENT_DATE - INTERVAL '6 month')

SELECT * FROM active_members

--5) Find Employees with the Most Book Issues Processed
--Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
SELECT 
	e.emp_name,
	count(issued_id) AS number_of_books,
	b.*
 FROM employees AS e
 JOIN issued_status AS ist 
 ON e.emp_id=ist.issued_emp_id
 JOIN branch AS b 
 ON  e.branch_id=b.branch_id
GROUP BY 1,3
ORDER BY number_of_books DESC
LIMIT 3

--6)Identify Members Issuing High-Risk Books
--Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books.

select * from books
select * from return_status


select 
	
	count(rs.book_quality)
	
	from books as bk join issued_status as ist 
on bk.isbn=ist.issued_book_isbn
join members as m
on m.member_id = ist.issued_member_id
join return_status as rs
on  rs.issued_id = ist.issued_id
group by 1,2

select m.member_name,
	bk.book_title, 
	count(ist.issued_id) as noo from members as m  join  issued_status as ist 
on m.member_id = ist.issued_member_id
join books as bk 
on bk.isbn = ist.issued_book_isbn
join return_status as rs 
on rs.issued_id = ist.issued_id
where book_quality = 'Damaged' AND  noo > 2
group by 1,2
 
select count(issued_id) from  issued_status


--7)Create a stored procedure to manage the status of books in a library system. 
--Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
--The procedure should function as follows: 
--The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10),p_issued_member_id VARCHAR(10),p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE 
	v_status VARCHAR (10);


BEGIN 
	SELECT status INTO v_status 
	FROM books
	where isbn = p_issued_book_isbn;

	IF v_status ='yes' THEN 

		INSERT INTO issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id)
		VALUES(p_issued_id,p_issued_member_id,CURRENT_DATE,p_issued_book_isbn,p_issued_emp_id);

		UPDATE books
		SET status='no'
		WHERE isbn=p_issued_book_isbn;

		RAISE NOTICE 'Book records added successfully for book isbn : %',p_issued_book_isbn;
		
		

	ELSE 
	
		RAISE NOTICE 'Sorry! Book isbn : % is currently unavailable  ',p_issued_book_isbn;
	END IF;	
	
END;
$$
--testing 
CALL issue_book('IS136','C107','978-0-7432-7357-1','E102') --no
CALL issue_book('IS155','C108','978-0-553-29698-2','E104') --yes

SELECT * FROM books 
WHERE isbn='978-0-553-29698-2'


--8) Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
--Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. The resulting table should show: Member ID Number of overdue books Total fines
select * from books

CREATE TABLE overdue_books AS 
select  m.*,
		ist.issued_id,
		bk.book_title,
		(CURRENT_DATE - ist.issued_date) as overdue
		from members as m join issued_status  as ist 
on m.member_id=ist.issued_member_id
join books as bk 
on bk.isbn = ist.issued_book_isbn
left join return_status as rs 
on ist.issued_id=rs.issued_id
where rs.return_date is null
and 
(current_date - ist.issued_date) > 90
group by 1,ist.issued_id,bk.book_title

ALTER TABLE overdue_books
ADD fine INT 
select * from overdue_books
UPDATE overdue_books
SET fine=(overdue*0.5)

ALTER TABLE overdue_books
ALTER COLUMN fine TYPE  FLOAT;



select * from return_status
select * from return_status 