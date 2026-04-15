from fastapi import APIRouter, HTTPException, Depends, Query
from datetime import datetime
from bson import ObjectId
from typing import Optional
from app.core.database import get_db
from app.core.security import get_current_admin, hash_password
from app.schemas.schemas import RegisterRequest, TokenResponse, UserResponse
from app.services.ws_manager import manager

router = APIRouter(prefix="/admin", tags=["Admin"])


# ─── DASHBOARD ────────────────────────────────────────────────────────────────

@router.get("/dashboard")
async def dashboard(admin=Depends(get_current_admin)):
    db = get_db()
    from datetime import timedelta
    now = datetime.utcnow()
    today = now - timedelta(hours=24)

    total_commands  = await db.command_logs.count_documents({})
    today_commands  = await db.command_logs.count_documents({"timestamp": {"$gte": today}})
    total_users     = await db.users.count_documents({})
    total_orders    = await db.orders.count_documents({})
    pending_orders  = await db.orders.count_documents({"status": "pending"})
    total_products  = await db.products.count_documents({"is_active": True})

    pipeline = [
        {"$match": {"timestamp": {"$gte": today}}},
        {"$group": {"_id": "$command", "count": {"$sum": 1}}},
    ]
    cmd_dist = await db.command_logs.aggregate(pipeline).to_list(length=10)

    ws_status = manager.get_status()

    return {
        "total_commands":       total_commands,
        "today_commands":       today_commands,
        "total_users":          total_users,
        "total_orders":         total_orders,
        "pending_orders":       pending_orders,
        "total_products":       total_products,
        "connected_cars":       ws_status["connected_cars"],
        "controller_counts":    ws_status["controller_counts"],
        "command_distribution": {item["_id"]: item["count"] for item in cmd_dist},
    }


# ─── KULLANICILAR ─────────────────────────────────────────────────────────────

def _serialize_user(u: dict) -> dict:
    u["id"]  = str(u["_id"])
    del u["_id"]
    u.pop("password_hash", None)
    return u


@router.get("/users")
async def list_users(
    search:   Optional[str] = None,
    role:     Optional[str] = None,
    page:     int = Query(1, ge=1),
    limit:    int = Query(20, ge=1, le=100),
    admin=Depends(get_current_admin),
):
    db = get_db()
    query: dict = {}
    if role:
        query["role"] = role
    if search:
        query["$or"] = [
            {"username":  {"$regex": search, "$options": "i"}},
            {"email":     {"$regex": search, "$options": "i"}},
            {"full_name": {"$regex": search, "$options": "i"}},
        ]

    skip   = (page - 1) * limit
    cursor = db.users.find(query).sort("created_at", -1).skip(skip).limit(limit)
    users  = await cursor.to_list(length=limit)
    total  = await db.users.count_documents(query)

    return {"total": total, "page": page, "users": [_serialize_user(u) for u in users]}


@router.get("/users/{user_id}")
async def get_user(user_id: str, admin=Depends(get_current_admin)):
    db = get_db()
    try:
        oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(400, "Geçersiz kullanıcı ID")
    user = await db.users.find_one({"_id": oid})
    if not user:
        raise HTTPException(404, "Kullanıcı bulunamadı")
    return _serialize_user(user)


@router.patch("/users/{user_id}")
async def update_user(user_id: str, data: dict, admin=Depends(get_current_admin)):
    db = get_db()
    try:
        oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(400, "Geçersiz kullanıcı ID")

    # Güvenli alanlar; admin başkasını admin yapabilir / kaldırabilir
    allowed = {"full_name", "phone", "role", "is_active", "language"}
    update  = {k: v for k, v in data.items() if k in allowed}
    if not update:
        raise HTTPException(400, "Güncellenecek geçerli alan yok")

    update["updated_at"] = datetime.utcnow()
    result = await db.users.find_one_and_update(
        {"_id": oid},
        {"$set": update},
        return_document=True,
    )
    if not result:
        raise HTTPException(404, "Kullanıcı bulunamadı")
    return _serialize_user(result)


@router.delete("/users/{user_id}")
async def delete_user(user_id: str, admin=Depends(get_current_admin)):
    db = get_db()
    try:
        oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(400, "Geçersiz kullanıcı ID")
    # Hard delete — ihtiyaca göre soft delete'e çevrilebilir
    result = await db.users.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(404, "Kullanıcı bulunamadı")
    return {"message": "Kullanıcı silindi"}


# ─── SİPARİŞLER ───────────────────────────────────────────────────────────────

@router.get("/orders")
async def list_orders(
    status:   Optional[str] = None,
    user_id:  Optional[str] = None,
    page:     int = Query(1, ge=1),
    limit:    int = Query(20, ge=1, le=100),
    admin=Depends(get_current_admin),
):
    db = get_db()
    query: dict = {}
    if status:
        query["status"] = status
    if user_id:
        try:
            query["user_id"] = ObjectId(user_id)
        except Exception:
            pass

    skip   = (page - 1) * limit
    cursor = db.orders.find(query).sort("created_at", -1).skip(skip).limit(limit)
    orders = await cursor.to_list(length=limit)
    total  = await db.orders.count_documents(query)

    for o in orders:
        o["id"]      = str(o["_id"])
        o["user_id"] = str(o["user_id"])
        del o["_id"]
        for item in o.get("items", []):
            item["product_id"] = str(item["product_id"])

    return {"total": total, "page": page, "orders": orders}


@router.get("/orders/{order_id}")
async def get_order(order_id: str, admin=Depends(get_current_admin)):
    db = get_db()
    try:
        oid = ObjectId(order_id)
    except Exception:
        raise HTTPException(400, "Geçersiz sipariş ID")
    order = await db.orders.find_one({"_id": oid})
    if not order:
        raise HTTPException(404, "Sipariş bulunamadı")
    order["id"]      = str(order["_id"])
    order["user_id"] = str(order["user_id"])
    del order["_id"]
    for item in order.get("items", []):
        item["product_id"] = str(item["product_id"])
    return order


@router.patch("/orders/{order_id}/status")
async def update_order_status(order_id: str, data: dict, admin=Depends(get_current_admin)):
    db = get_db()
    allowed_statuses = {"pending", "paid", "shipped", "delivered", "cancelled"}
    new_status = data.get("status")
    if new_status not in allowed_statuses:
        raise HTTPException(400, f"Geçersiz durum. İzin verilenler: {allowed_statuses}")
    try:
        oid = ObjectId(order_id)
    except Exception:
        raise HTTPException(400, "Geçersiz sipariş ID")
    result = await db.orders.find_one_and_update(
        {"_id": oid},
        {"$set": {"status": new_status, "updated_at": datetime.utcnow()}},
        return_document=True,
    )
    if not result:
        raise HTTPException(404, "Sipariş bulunamadı")
    result["id"]      = str(result["_id"])
    result["user_id"] = str(result["user_id"])
    del result["_id"]
    return result


# ─── ÜRÜNLER (admin görünümü — pasif ürünler dahil) ──────────────────────────

@router.get("/products")
async def list_admin_products(
    category: Optional[str] = None,
    search:   Optional[str] = None,
    page:     int = Query(1, ge=1),
    limit:    int = Query(20, ge=1, le=100),
    admin=Depends(get_current_admin),
):
    db = get_db()
    query: dict = {}   # admin pasif ürünleri de görür
    if category:
        query["category"] = category
    if search:
        query["$or"] = [
            {"name.tr":        {"$regex": search, "$options": "i"}},
            {"name.en":        {"$regex": search, "$options": "i"}},
            {"description.tr": {"$regex": search, "$options": "i"}},
        ]

    skip     = (page - 1) * limit
    cursor   = db.products.find(query).sort("created_at", -1).skip(skip).limit(limit)
    products = await cursor.to_list(length=limit)
    total    = await db.products.count_documents(query)

    for p in products:
        p["id"] = str(p["_id"])
        del p["_id"]

    return {"total": total, "page": page, "products": products}


# ─── YENİ KULLANICI / ADMIN OLUŞTUR ──────────────────────────────────────────

@router.post("/users")
async def create_user(data: dict, admin=Depends(get_current_admin)):
    db = get_db()

    required = {"email", "username", "password", "full_name"}
    if not required.issubset(data.keys()):
        raise HTTPException(400, f"Zorunlu alanlar eksik: {required}")

    if await db.users.find_one({"email": data["email"]}):
        raise HTTPException(400, "Bu email zaten kayıtlı")
    if await db.users.find_one({"username": data["username"]}):
        raise HTTPException(400, "Bu kullanıcı adı alınmış")

    role = data.get("role", "user")
    if role not in {"user", "admin"}:
        raise HTTPException(400, "Geçersiz rol")

    user = {
        "email":         data["email"],
        "username":      data["username"],
        "password_hash": hash_password(data["password"]),
        "full_name":     data["full_name"],
        "phone":         data.get("phone"),
        "role":          role,
        "language":      data.get("language", "tr"),
        "address":       None,
        "is_active":     True,
        "created_at":    datetime.utcnow(),
        "updated_at":    datetime.utcnow(),
    }
    result = await db.users.insert_one(user)
    user["_id"] = result.inserted_id
    return _serialize_user(user)


# ─── BAĞLI ARABALAR ───────────────────────────────────────────────────────────

@router.get("/cars/connected")
async def connected_cars(admin=Depends(get_current_admin)):
    return manager.get_status()