"""Acceptance test for Laundry Desk (JSP). Uses only the Python standard library.

Run it against a fresh start of the website (the database is re-seeded at every start):

    python tests/acceptance_test.py                       # http://localhost:8080
    python tests/acceptance_test.py https://your-site.onrender.com
"""
import html
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from http.cookiejar import CookieJar

BASE = (sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080").rstrip("/")
results = []


class Browser:
    def __init__(self):
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(CookieJar()))
        self.page = ""
        self.url = ""
        self.status = 0

    def _open(self, request):
        try:
            response = self.opener.open(request, timeout=60)
        except urllib.error.HTTPError as error:
            response = error
        self.status = response.status if hasattr(response, "status") else response.code
        self.url = response.geturl()
        self.page = response.read().decode("utf-8", "replace")
        return self

    def get(self, path):
        return self._open(urllib.request.Request(BASE + path))

    def token(self):
        found = re.search(r'name="_csrf" value="([^"]+)"', self.page)
        if not found:
            self.get("/login.jsp" if "Logout" not in self.page else "/index.jsp")
            found = re.search(r'name="_csrf" value="([^"]+)"', self.page)
        return found.group(1) if found else ""

    def post(self, path, data, with_token=True):
        fields = dict(data)
        if with_token:
            fields["_csrf"] = self.token()
        body = urllib.parse.urlencode(fields).encode()
        return self._open(urllib.request.Request(BASE + path, data=body))

    @property
    def text(self):
        return html.unescape(self.page)


def check(name, condition, detail=""):
    results.append((name, bool(condition), detail))
    print(("PASS  " if condition else "FAIL  ") + name + ("" if condition else "   <- " + detail))


def count(browser, label):
    return browser.page.count('data-label="%s"' % label)


def login(browser, email, password="password123"):
    browser.get("/login.jsp")
    return browser.post("/login.jsp", {"email": email, "password": password})


# ---------------------------------------------------------------- public pages
guest = Browser()
guest.get("/")
check("01 Home page opens", guest.status == 200 and "Laundry Desk" in guest.text)
check("02 Home page has the theme toggle button", 'id="theme-toggle"' in guest.page)
guest.get("/services.jsp")
check("03 Price list shows 8 services without login", count(guest, "Service") == 8 and "Rp 8.000" in guest.text,
      "services=%d" % count(guest, "Service"))
guest.get("/schema.jsp")
check("04 Data model page lists 7 tables and 10 foreign keys",
      guest.page.count('<section class="panel">') == 7 and guest.text.count("FK ") == 10,
      "tables=%d fks=%d" % (guest.page.count('<section class="panel">'), guest.text.count("FK ")))

# ---------------------------------------------------------------- access control
guest.get("/customers.jsp")
check("05 A visitor who opens /customers goes to the login page",
      guest.url.endswith("/login.jsp") and "Please log in first." in guest.text, guest.url)
guest.get("/login.jsp")
guest.post("/login.jsp", {"email": "rina@laundrydesk.test", "password": "wrong-password"})
check("06 Wrong password shows an error message", "Email or password is incorrect." in guest.text)
guest.get("/login.jsp")
guest.post("/login.jsp", {"email": "rina@laundrydesk.test", "password": "password123"}, with_token=False)
check("07 A form without the CSRF token is refused (403)", guest.status == 403, str(guest.status))

# ---------------------------------------------------------------- staff
staff = login(Browser(), "rina@laundrydesk.test")
check("08 Staff login goes to the bill list", staff.url.endswith("/bills.jsp"), staff.url)
check("09 Bill list has 30 bills on 3 pages", count(staff, "Bill") == 10 and "Page 1 of 3" in staff.text,
      "rows=%d" % count(staff, "Bill"))
check("10 Newest seeded bill B0030 is Finished with balance Rp 22.500",
      "B0030" in staff.text and "Rp 22.500" in staff.text and "Finished" in staff.text)
staff.get("/bills.jsp?status=cancelled")
check("11 Status filter shows only the cancelled bill", count(staff, "Bill") == 1 and "B0007" in staff.text)

staff.get("/customers.jsp")
check("12 Customer list has 20 customers on 2 pages", "Page 1 of 2" in staff.text and count(staff, "Code") == 10)
staff.get("/customers.jsp?q=galih")
check("13 Search finds Galih Setiawan", count(staff, "Code") == 1 and "Galih Setiawan" in staff.text)
staff.get("/customers.jsp?q=zzz")
check("14 Search with an unknown word shows the empty message", "No customers match your search." in staff.text)

staff.get("/customer-form.jsp")
staff.post("/customer-form.jsp", {"name": "Test Customer", "phone": "abc", "address": ""})
check("15 Phone number 'abc' is rejected and the form stays open",
      "Use digits, plus, minus and spaces only" in staff.text and "Test Customer" in staff.text)
staff.post("/customer-form.jsp", {"name": "Test Customer", "phone": "0811 2233 4455", "address": "Jl. Contoh 1"})
added = re.search(r"Customer (C\d{4}) \(Test Customer\) was added\.", staff.text)
check("16 A valid customer is added with a new code", added is not None and staff.url.endswith("/customers.jsp"))
new_code = added.group(1) if added else "C0021"
staff.get("/customers.jsp?q=Test+Customer")
new_id = re.search(r"customer-form\.jsp\?id=(\d+)", staff.page)
new_id = new_id.group(1) if new_id else "21"
staff.get("/customer-form.jsp?id=" + new_id)
check("17 The edit form is filled with the saved data", 'value="Test Customer"' in staff.page)
staff.post("/customer-form.jsp?id=" + new_id, {"name": "Test Customer", "phone": "0811 9999 0000", "address": "Jl. Baru 2"})
check("18 Editing a customer shows a success message", ("Customer %s was updated." % new_code) in staff.text)

staff.get("/customer-form.jsp")
staff.post("/customer-form.jsp", {"name": "<script>alert(1)</script>", "phone": "0811 2233 4455", "address": ""})
staff.get("/customers.jsp?q=script")
check("19 HTML in a name is escaped on the page",
      "&lt;script&gt;" in staff.page and "<script>alert(1)</script>" not in staff.page)
xss_id = re.search(r"customer-form\.jsp\?id=(\d+)", staff.page)
if xss_id:
    staff.post("/customer-delete.jsp", {"id": xss_id.group(1)})

staff.get("/customers.jsp?q=galih")
galih = re.search(r"customer-form\.jsp\?id=(\d+)", staff.page).group(1)
staff.post("/customer-delete.jsp", {"id": galih})
check("20 A customer with bills cannot be deleted",
      "cannot be deleted because they still have 2 bill(s)." in staff.text)
staff.post("/customer-delete.jsp", {"id": new_id})
check("21 A customer without bills can be deleted", ("Customer %s was deleted." % new_code) in staff.text)

# ---------------------------------------------------------------- new bill, status, payments
staff.get("/bill-new.jsp")
staff.post("/bill-new.jsp", {"customer_id": "2", "service_id": "1", "unit": "0"})
check("22 Quantity 0 is rejected", "whole number from 1 to 100" in staff.text)
staff.post("/bill-new.jsp", {"customer_id": "2", "service_id": "1", "unit": "101"})
check("23 Quantity 101 is rejected", "whole number from 1 to 100" in staff.text)
staff.post("/bill-new.jsp", {"customer_id": "", "service_id": "1", "unit": "3"})
check("24 A bill without a customer is rejected", "Choose a customer from the list." in staff.text)
staff.post("/bill-new.jsp", {"customer_id": "2", "service_id": "1", "unit": "3"})
check("25 New bill: 3 kg wash and fold costs Rp 24.000, status Received, Keputih Outlet",
      "B0031" in staff.text and "Rp 24.000" in staff.text and "Received" in staff.text and "Keputih Outlet" in staff.text)
bill_url = staff.url
bill_id = re.search(r"id=(\d+)", bill_url).group(1)

staff.post("/bill-advance.jsp", {"id": bill_id})
check("26 Moving to finished adds a history entry", "Bill B0031 is now finished." in staff.text and "Finished" in staff.text)
staff.post("/bill-advance.jsp", {"id": bill_id})
check("27 Moving to collected removes the button",
      "Bill B0031 is now collected." in staff.text and "Move to" not in staff.text)
staff.post("/bill-advance.jsp", {"id": bill_id})
check("28 A collected bill cannot move on", "already collected and cannot move on" in staff.text)

staff.post("/bill-pay.jsp", {"id": bill_id, "amount": "10000"})
check("29 A part payment lowers the balance",
      "Payment was recorded." in staff.text and "Rp 10.000" in staff.text and "Rp 14.000" in staff.text)
staff.post("/bill-pay.jsp", {"id": bill_id, "amount": "20000"})
check("30 A payment above the balance is rejected", "more than the remaining balance" in staff.text)
staff.post("/bill-pay.jsp", {"id": bill_id, "amount": "0"})
check("31 A payment of 0 is rejected", "at least Rp 1" in staff.text)
staff.post("/bill-pay.jsp", {"id": bill_id, "amount": "14000"})
check("32 Paying the rest closes the bill (balance Rp 0, no payment form)",
      "Nothing left to pay on this bill." in staff.text)
staff.get("/bill.jsp?id=9999")
check("33 An unknown bill shows the 404 page", staff.status == 404)

staff.opener.close()

# ---------------------------------------------------------------- customer
customer = login(Browser(), "bayu@laundrydesk.test")
check("34 Customer login goes to My bills", customer.url.endswith("/my-bills.jsp"), customer.url)
check("35 Customer sees only own bill B0020 with balance Rp 0",
      count(customer, "Bill") == 1 and "B0020" in customer.text and "Bed cover" in customer.text)
customer.get("/customers.jsp")
check("36 A customer opening /customers gets the 403 page",
      customer.status == 403 and "This page is for staff only." in customer.text, str(customer.status))
customer.get("/bills.jsp")
check("37 A customer opening /bills gets the 403 page", customer.status == 403)
customer.post("/logout.jsp", {})
check("38 Logout returns to the home page with a message",
      customer.url.endswith("/index.jsp") and "You are logged out." in customer.text, customer.url)

# ---------------------------------------------------------------- register
newbie = Browser()
newbie.get("/register.jsp")
newbie.post("/register.jsp", {"name": "Rani Tester", "email": "rani@example.com", "phone": "0812 1111 2222",
                              "password": "short", "password_again": "short"})
check("39 A short password is rejected", "at least 8 characters" in newbie.text)
newbie.post("/register.jsp", {"name": "Rani Tester", "email": "rina@laundrydesk.test", "phone": "0812 1111 2222",
                              "password": "longenough1", "password_again": "longenough1"})
check("40 An email that is already used is rejected", "already registered" in newbie.text)
newbie.post("/register.jsp", {"name": "Rani Tester", "email": "rani@example.com", "phone": "0812 1111 2222",
                              "password": "longenough1", "password_again": "different1"})
check("41 Two different passwords are rejected", "not the same" in newbie.text)
newbie.post("/register.jsp", {"name": "Rani Tester", "email": "rani@example.com", "phone": "0812 1111 2222",
                              "password": "longenough1", "password_again": "longenough1"})
check("42 Registration creates the account and shows an empty bill list",
      newbie.url.endswith("/my-bills.jsp") and "You have no bills yet." in newbie.text and "Welcome, Rani Tester" in newbie.text,
      newbie.url)

failed = [r for r in results if not r[1]]
print("\n%d tests, %d passed, %d failed" % (len(results), len(results) - len(failed), len(failed)))
sys.exit(1 if failed else 0)
