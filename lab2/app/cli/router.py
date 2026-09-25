from app.menus.customer_menu import customer_menu
from app.menus.employee_menu import employee_menu
from app.menus.logistics_menu import logistics_menu
from app.menus.stockroom_menu import stockroom_menu
from app.menus.manager_menu import manager_menu
from app.menus.admin_menu import admin_menu
from app.menus.supplier_menu import supplier_menu

ROLE_ROUTES = {
    "customer": customer_menu,
    "employee": employee_menu,
    "logistics": logistics_menu,
    "stockroom": stockroom_menu,
    "manager": manager_menu,
    "admin": admin_menu,
    "supplier": supplier_menu,
}

def route_user(user):
    role = (user.get("role") or "").lower()
    menu = ROLE_ROUTES.get(role)
    if menu:
        menu(user)
    else:
        print("Unknown role. Contact administrator.")
