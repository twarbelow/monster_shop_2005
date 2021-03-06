class Merchant::DashboardController < ApplicationController
  before_action :require_merchant

  def index
    @merchant = Merchant.find(current_user.merchant_id)
    @pending_orders = @merchant.orders.where('orders.status = ?', 'Pending').distinct
  end

  def show
    @order = Order.find(params[:order_id])
    @merchant_id = User.find(session[:user_id]).merchant_id
  end

  def new
    @item = Item.new
  end

  def create
    merchant = Merchant.find(current_user.merchant_id)
    item = merchant.items.create(item_params)
    if item.save
      redirect_to "/merchant/items"
      flash[:notice] = "#{item.name} saved!"
    else
      redirect_to request.referrer
      flash[:error] = item.errors.full_messages.to_sentence
    end
  end

  def fulfill_item
    item_order = ItemOrder.where(item_id: params[:item_id], order_id: params[:order_id]).first
    item_order.status = "Fulfilled"
    item_order.save
    item = Item.find(params[:item_id])
    item.inventory -= item_order.quantity
    flash[:notice] = "Item fulfilled!" if item.save
    order = Order.find(params[:order_id])
    all_order_items = ItemOrder.where('order_id=?', params[:order_id])
    fulfilled = all_order_items.all? {|item| item.status == "Fulfilled"}
    if fulfilled
      order.status = "Packaged"
      order.save
    end
    redirect_to request.referrer
  end

  def items
    @merchant = Merchant.find(current_user.merchant_id)
  end

  def change_item_status
    item = Item.find(params[:item_id])
    item.toggle!(:active?)
    if item.active?
      flash[:alert] = "Item activated!"
    else
      flash[:alert] = "Item deactivated!"
    end
    redirect_to request.referrer
  end

  def require_merchant
    render file: "/public/404" unless current_merchant?
  end

  def destroy
     Item.destroy(params[:item_id])
     flash[:alert] = "Item deleted!"
     redirect_to request.referrer
  end

  def show_item
    @item = Item.find(params[:item_id])
  end

  private

  def item_params
    params.require(:item).permit(:name,:description,:price,:inventory,:image)
  end
end
