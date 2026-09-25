# app/init/users_init.py

from sqlalchemy.orm import Session
from app.db import engine
from app.models.role import Roles
from app.models.user import User
from app.models.employee import Employees
from app.models.store import Stores
from app.models.user_store_access import UserStoreAccess
from app.security.password import hash_password


# ---------------------------------------------------------
# Helper: get or create role
# ---------------------------------------------------------
def get_or_create_role(db: Session, role_name: str):
    role = db.query(Roles).filter(Roles.role_name == role_name).first()
    if not role:
        role = Roles(role_name=role_name)
        db.add(role)
        db.commit()
        db.refresh(role)
    return role


# ---------------------------------------------------------
# Helper: get or create store
# ---------------------------------------------------------
def get_store(db: Session, store_id: int):
    return db.query(Stores).filter(Stores.store_id == store_id).first()


# ---------------------------------------------------------
# Helper: create user + employee profile
# ---------------------------------------------------------
def create_user_with_profile(
        db: Session,
        username: str,
        password: str,
        role: Roles,
        first_name: str,
        last_name: str,
        email: str
):
    # Check if user exists
    existing = db.query(User).filter(User.username == username).first()
    if existing:
        return existing

    user = User(
        username=username,
        password_hash=hash_password(password),
        role_id=role.role_id
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Create employee profile
    emp = Employees(
        user_id=user.user_id,
        role_id=role.role_id,
        first_name=first_name,
        last_name=last_name,
        email=email
    )
    db.add(emp)
    db.commit()

    return user


# ---------------------------------------------------------
# Helper: assign store access
# ---------------------------------------------------------
def assign_store_access(db: Session, user_id: int, store_id: int):
    exists = (
        db.query(UserStoreAccess)
        .filter(UserStoreAccess.user_id == user_id,
                UserStoreAccess.store_id == store_id)
        .first()
    )
    if exists:
        return exists

    access = UserStoreAccess(user_id=user_id, store_id=store_id)
    db.add(access)
    db.commit()
    return access


# ---------------------------------------------------------
# MAIN INITIALIZER
# ---------------------------------------------------------
def initialize_users():
    db = Session(bind=engine)

    print("Seeding roles...")
    admin_role = get_or_create_role(db, "admin")
    manager_role = get_or_create_role(db, "manager")
    employee_role = get_or_create_role(db, "employee")
    logistics_role = get_or_create_role(db, "logistics")
    stockroom_role = get_or_create_role(db, "stockroom")
    supplier_role = get_or_create_role(db, "supplier")

    print("Seeding stores...")
    # These must already exist in Stores table
    CENTRAL = 1
    NORTH = 2
    MALMO = 3
    STOCKHOLM = 4
    LUND = 5
    ONLINE = 6
    HEDE = 7

    # ---------------------------------------------------------
    # Admin
    # ---------------------------------------------------------
    print("Creating admin...")
    admin = create_user_with_profile(
        db, "admin", "Admin123!", admin_role,
        "System", "Administrator", "admin@codeblockbooks.se"
    )
    assign_store_access(db, admin.user_id, CENTRAL)

    # ---------------------------------------------------------
    # Managers
    # ---------------------------------------------------------
    print("Creating managers...")
    mgr_central = create_user_with_profile(
        db, "mgr_central", "Manager123!", manager_role,
        "Anna", "Central", "anna.central@codeblockbooks.se"
    )
    assign_store_access(db, mgr_central.user_id, CENTRAL)

    mgr_south = create_user_with_profile(
        db, "mgr_south", "Manager123!", manager_role,
        "Oskar", "South", "oskar.south@codeblockbooks.se"
    )
    assign_store_access(db, mgr_south.user_id, LUND)

    mgr_west = create_user_with_profile(
        db, "mgr_west", "Manager123!", manager_role,
        "Sara", "West", "sara.west@codeblockbooks.se"
    )
    assign_store_access(db, mgr_west.user_id, STOCKHOLM)

    # ---------------------------------------------------------
    # Logistics, Stockroom, Supplier
    # ---------------------------------------------------------
    print("Creating logistics, stockroom, supplier...")
    logistics = create_user_with_profile(
        db, "logistics", "Logi123!", logistics_role,
        "David", "Logistics", "logistics@codeblockbooks.se"
    )
    assign_store_access(db, logistics.user_id, ONLINE)

    stockroom = create_user_with_profile(
        db, "stockroom", "Stock123!", stockroom_role,
        "Nina", "Stockroom", "stockroom@codeblockbooks.se"
    )
    assign_store_access(db, stockroom.user_id, ONLINE)

    supplier_mgr = create_user_with_profile(
        db, "supplier_mgr", "Supplier123!", supplier_role,
        "Carl", "Supplier", "supplier@codeblockbooks.se"
    )
    assign_store_access(db, supplier_mgr.user_id, ONLINE)

    # ---------------------------------------------------------
    # Employees (2 per store)
    # ---------------------------------------------------------
    print("Creating employees...")
    stores = {
        CENTRAL: "central",
        NORTH: "north",
        MALMO: "malmo",
        STOCKHOLM: "stockholm",
        LUND: "lund",
        ONLINE: "online",
        HEDE: "hede"
    }

    for store_id, name in stores.items():
        for i in range(1, 3):
            username = f"emp_{name}_{i}"
            user = create_user_with_profile(
                db,
                username=username,
                password="Employee123!",
                role=employee_role,
                first_name=f"Emp{name.capitalize()}",
                last_name=str(i),
                email=f"{username}@codeblockbooks.se"
            )
            assign_store_access(db, user.user_id, store_id)

    print("User initialization complete.")


if __name__ == "__main__":
    initialize_users()
