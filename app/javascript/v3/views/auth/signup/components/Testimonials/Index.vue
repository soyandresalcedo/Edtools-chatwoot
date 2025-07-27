<script>
export default {
  emits: ['resizeContainers'],
  data() {
    return {
      testimonials: [
        {
          id: 1,
          authorReview:
            "Edtools is great! Using them for our startup VideoTouch and I'm very satisfied! Great open source alternative of Intercom, Crisp, and other expensive chats for websites. 😎",
          authorImage: 'https://via.placeholder.com/40',
          authorName: 'John Doe',
          authorCompany: 'VideoTouch',
        },
      ],
    };
  },
  beforeMount() {
    this.$emit('resizeContainers', !!this.testimonials.length);
  },
};
</script>

<template>
  <div
    v-show="testimonials.length"
    class="relative flex-1 min-h-screen hidden overflow-hidden xl:flex bg-gray-800"
  >
    <img
      src="dashboard/assets/images/auth/SingUp.png"
      class="h-[96%] left-[6%] top-[8%] w-[96%] absolute"
    />
  </div>
</template>

<style lang="scss" scoped>
.center--img {
}
</style>
